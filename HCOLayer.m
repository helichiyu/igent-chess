function lgraph = HCOLayer(lgraph,actionLayerName,inputLayerName,blockName,inputchannel)
% 构建
bn1 = batchNormalizationLayer('Name',[blockName '_bn1']);
dwconv = groupedConvolution2dLayer(3,1,inputchannel,'Padding','same','Name',[blockName '_dwc']);
hco = functionLayer(@HeatConductionOperator,'Name',[blockName '_hco']);
bn2 = batchNormalizationLayer('Name',[blockName '_bn2']);
gelu = geluLayer('Name',[blockName '_gelu']);
mul = multiplicationLayer(2,"Name",[blockName '_mul']);
add = additionLayer(2, 'Name', [blockName '_add']);
% 添加
lgraph = addLayers(lgraph,bn1);
lgraph = addLayers(lgraph,dwconv);
lgraph = addLayers(lgraph,hco);
lgraph = addLayers(lgraph,bn2);
lgraph = addLayers(lgraph,gelu);
lgraph = addLayers(lgraph,mul);
lgraph = addLayers(lgraph,add);
% 连接
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_bn1']);
lgraph = connectLayers(lgraph,[blockName '_bn1'],[blockName '_dwc']);
lgraph = rCLLayer(lgraph,actionLayerName,[blockName '_dwc'],[blockName '_rcl1'],inputchannel);
lgraph = connectLayers(lgraph,[blockName '_rcl1_resh'],[blockName '_hco']);
lgraph = connectLayers(lgraph,[blockName '_hco'],[blockName '_bn2']);
lgraph = connectLayers(lgraph,[blockName '_bn2'],[blockName '_mul/in1']);
lgraph = rCLLayer(lgraph,actionLayerName,[blockName '_dwc'],[blockName '_rcl2'],inputchannel);
lgraph = connectLayers(lgraph,[blockName '_rcl2_resh'],[blockName '_gelu']);
lgraph = connectLayers(lgraph,[blockName '_gelu'],[blockName '_mul/in2']);
lgraph = rCLLayer(lgraph,actionLayerName,[blockName '_mul'],[blockName '_rcl3'],inputchannel);
lgraph = connectLayers(lgraph,[blockName '_rcl3_resh'],[blockName '_add/in1']);
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_add/in2']);
end