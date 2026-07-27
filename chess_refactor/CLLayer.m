function lgraph = CLLayer(lgraph,actionLayerName,inputLayerName,blockName,inputchannel,outputchannel)
% 创建降维层
reshapeFunc = @(X) dlarray(reshape(X,90,size(X,3),size(X,4)),'SCB');
reduction = functionLayer(reshapeFunc,'Acceleratable',true,'Formattable',true,'Name',[blockName '_re']);
% 创造生成通道层
generationFunc = @(X) dlarray(repmat(reshape(X,4,1,size(X,4)),1,inputchannel,1),'SCB');
generation = functionLayer(generationFunc,'Acceleratable',true,'Formattable',true,'Name',[blockName '_ge']);
% 构建展开流程
concatenation = concatenationLayer(1,2,'Name',[blockName '_co']);
drop = dropoutLayer(0.2,"Name",[blockName '_drop']);
linear = fullyConnectedLayer(outputchannel,'Name',[blockName '_fc']);
% 添加层到网络中
lgraph = addLayers(lgraph,reduction);
lgraph = addLayers(lgraph,generation);
lgraph = addLayers(lgraph,concatenation);
lgraph = addLayers(lgraph,drop);
lgraph = addLayers(lgraph,linear);
% 根据名称连接层
lgraph = connectLayers(lgraph,inputLayerName,[blockName '_re']);
lgraph = connectLayers(lgraph,actionLayerName,[blockName '_ge']);
lgraph = connectLayers(lgraph,[blockName '_re'],[blockName '_co/in1']);
lgraph = connectLayers(lgraph,[blockName '_ge'],[blockName '_co/in2']);
lgraph = connectLayers(lgraph,[blockName '_co'],[blockName '_drop']);
lgraph = connectLayers(lgraph,[blockName '_drop'],[blockName '_fc']);
end