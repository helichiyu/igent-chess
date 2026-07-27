function lgraph = chess1network()
% 可调参数
channel1 = 128;
channel2 = 16;
channel3 = 2;
% 构建
input1 = imageInputLayer([10 9 1],'Name','input1');
input2 = imageInputLayer([4 1 1],'Name','input2');
flatten1 = flattenLayer("Name",'fl1');
flatten2 = flattenLayer("Name",'fl2');
concatenation = concatenationLayer(1,2,'Name','con');

linear1 = fullyConnectedLayer(channel1,'Name','fc1');
bn1 = batchNormalizationLayer('Name','bn1');
tanh1 = tanhLayer('Name','tanh1');
drop1 = dropoutLayer(0.5,"Name",'drop1');

linear2 = fullyConnectedLayer(channel2,'Name','fc2');
bn2 = batchNormalizationLayer('Name','bn2');
tanh2 = geluLayer('Name','tanh2');
drop2 = dropoutLayer(0.5,"Name",'drop2');

linear3 = fullyConnectedLayer(channel3,'Name','fc3');
% 添加
lgraph = layerGraph();
lgraph = addLayers(lgraph,input1);
lgraph = addLayers(lgraph,input2);
lgraph = addLayers(lgraph,flatten1);
lgraph = addLayers(lgraph,flatten2);
lgraph = addLayers(lgraph,concatenation);

lgraph = addLayers(lgraph,linear1);
lgraph = addLayers(lgraph,bn1);
lgraph = addLayers(lgraph,tanh1);
lgraph = addLayers(lgraph,drop1);

lgraph = addLayers(lgraph,linear2);
lgraph = addLayers(lgraph,bn2);
lgraph = addLayers(lgraph,tanh2);
lgraph = addLayers(lgraph,drop2);

lgraph = addLayers(lgraph,linear3);
% 连接
lgraph = connectLayers(lgraph,'input1','fl1');
lgraph = connectLayers(lgraph,'input2','fl2');
lgraph = connectLayers(lgraph,'fl1','con/in1');
lgraph = connectLayers(lgraph,'fl2','con/in2');

lgraph = connectLayers(lgraph,'con','fc1');
lgraph = connectLayers(lgraph,'fc1','bn1');
lgraph = connectLayers(lgraph,'bn1','tanh1');
lgraph = connectLayers(lgraph,'tanh1','drop1');

lgraph = connectLayers(lgraph,'drop1','fc2');
lgraph = connectLayers(lgraph,'fc2','bn2');
lgraph = connectLayers(lgraph,'bn2','tanh2');
lgraph = connectLayers(lgraph,'tanh2','drop2');

lgraph = connectLayers(lgraph,'drop2','fc3');
end