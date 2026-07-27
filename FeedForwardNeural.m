function lgraph = FeedForwardNeural(lgraph,actionLayerName,inputLayerName,blockName,inputchannel)
% 构建
bn = batchNormalizationLayer('Name',[blockName '_bn']);
gelu = geluLayer('Name',[blockName '_gelu']);
flatten = flattenLayer("Name",[blockName '_fl']);
drop = dropoutLayer(0.2,"Name",[blockName '_drop']);
linear = fullyConnectedLayer(2,'Name',[blockName '_fc']);
% 添加
lgraph = addLayers(lgraph,bn);
lgraph = addLayers(lgraph,gelu);
lgraph = addLayers(lgraph,flatten);
lgraph = addLayers(lgraph,drop);
lgraph = addLayers(lgraph,linear);
% 连接
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_bn']);
lgraph = CLLayer(lgraph,actionLayerName,[blockName '_bn'],[blockName '_cl'],inputchannel,16);
lgraph = connectLayers(lgraph,[blockName '_cl_fc'],[blockName '_gelu']);
lgraph = connectLayers(lgraph,[blockName '_gelu'],[blockName '_fl']);
lgraph = connectLayers(lgraph,[blockName '_fl'],[blockName '_drop']);
lgraph = connectLayers(lgraph,[blockName '_drop'],[blockName '_fc']);
end