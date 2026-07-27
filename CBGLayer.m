function lgraph = CBGLayer(lgraph,inputLayerName,blockName,kernelsize,outputchannel)
% 构建
conv = convolution2dLayer(kernelsize,outputchannel,'Padding','same','Name',[blockName '_conv']);
bn = batchNormalizationLayer('Name',[blockName '_bn']);
gelu = geluLayer('Name',[blockName '_gelu']);
% 添加
lgraph = addLayers(lgraph,conv);
lgraph = addLayers(lgraph,bn);
lgraph = addLayers(lgraph,gelu);
% 连接
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_conv']);
lgraph = connectLayers(lgraph,[blockName '_conv'],[blockName '_bn']);
lgraph = connectLayers(lgraph,[blockName '_bn'],[blockName '_gelu']);
end