function lgraph = rCLLayer(lgraph,actionLayerName,inputLayerName,blockName,inputchannel)
% 创建降维层
reshapeFunc = @(X) dlarray(reshape(X,90,size(X,3),size(X,4)),'SCB');
reduction = functionLayer(reshapeFunc,'Acceleratable',true,'Formattable',true,'Name',[blockName '_redu']);
% 创造生成通道层
generationFunc = @(X) dlarray(repmat(reshape(X,4,1,size(X,4)),1,inputchannel,1),'SCB');
generation = functionLayer(generationFunc,'Acceleratable',true,'Formattable',true,'Name',[blockName '_ge']);
% 创建重塑层
reshapeFunc = @(X) dlarray(reshape(X,10,9,size(X,2),size(X,3)),'SSCB');
reshap = functionLayer(reshapeFunc,'Acceleratable',true,'Formattable',true,'Name',[blockName '_resh']);
% 构建展开流程
concatenation = concatenationLayer(1,2,'Name',[blockName '_co']);
linear = convolution1dLayer(5,inputchannel,'Name',[blockName '_conv1d']);
% 添加层到网络中
lgraph = addLayers(lgraph,reduction);
lgraph = addLayers(lgraph,generation);
lgraph = addLayers(lgraph,concatenation);
lgraph = addLayers(lgraph,linear);
lgraph = addLayers(lgraph,reshap);
% 根据名称连接层
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_redu']);
lgraph = connectLayers(lgraph,actionLayerName,[blockName '_ge']);
lgraph = connectLayers(lgraph,[blockName '_redu'],[blockName '_co/in1']);
lgraph = connectLayers(lgraph,[blockName '_ge'],[blockName '_co/in2']);
lgraph = connectLayers(lgraph,[blockName '_co'],[blockName '_conv1d']);
lgraph = connectLayers(lgraph,[blockName '_conv1d'],[blockName '_resh']);
end