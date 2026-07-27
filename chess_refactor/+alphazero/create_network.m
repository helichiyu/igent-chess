function net = create_network()
%CREATE_NETWORK Build the small shared policy-value network for validation.
layers = [ ...
    imageInputLayer([10 9 14], Normalization="none", Name="state")
    convolution2dLayer(3, 32, Padding="same", Name="conv1")
    reluLayer(Name="relu1")
    convolution2dLayer(3, 32, Padding="same", Name="conv2")
    reluLayer(Name="relu2")
    globalAveragePooling2dLayer(Name="pool")
    fullyConnectedLayer(128, Name="features")
    reluLayer(Name="feature_relu")
    fullyConnectedLayer(8101, Name="policy_value")];
net = dlnetwork(layers);
end
