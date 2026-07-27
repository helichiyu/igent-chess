function net = create_fullgame_network(settings)
%CREATE_FULLGAME_NETWORK Build a spatial residual policy-value network.
if nargin < 1 || isempty(settings)
    settings = alphazero.fullgame_config();
end

layers = [ ...
    imageInputLayer([10 9 14], Normalization="none", Name="state")
    convolution2dLayer(3, settings.networkFilters, Padding="same", Name="stem_conv")
    reluLayer(Name="stem_relu")];
graph = layerGraph(layers);
previous = "stem_relu";
for block = 1:settings.residualBlocks
    prefix = sprintf("res%d", block);
    graph = addLayers(graph, [ ...
        convolution2dLayer(3, settings.networkFilters, Padding="same", Name=prefix + "_conv1")
        reluLayer(Name=prefix + "_relu1")
        convolution2dLayer(3, settings.networkFilters, Padding="same", Name=prefix + "_conv2")]);
    graph = addLayers(graph, additionLayer(2, Name=prefix + "_add"));
    graph = addLayers(graph, reluLayer(Name=prefix + "_relu2"));
    graph = connectLayers(graph, previous, prefix + "_conv1");
    graph = connectLayers(graph, previous, prefix + "_add/in2");
    graph = connectLayers(graph, prefix + "_conv2", prefix + "_add/in1");
    graph = connectLayers(graph, prefix + "_add", prefix + "_relu2");
    previous = prefix + "_relu2";
end
graph = addLayers(graph, [ ...
    flattenLayer(Name="spatial_features")
    fullyConnectedLayer(settings.featureWidth, Name="features")
    reluLayer(Name="feature_relu")
    fullyConnectedLayer(8101, Name="policy_value")]);
graph = connectLayers(graph, previous, "spatial_features");
net = dlnetwork(graph);
end
