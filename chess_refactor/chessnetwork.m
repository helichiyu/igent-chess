function lgraph = chessnetwork()
% 可调参数
channel1 = 4;
channel2 = 8;
channel3 = 8;
channel4 = 8;
% 构建
input1 = imageInputLayer([10 9 1],'Name','input1');
input2 = imageInputLayer([4 1 1],'Name','input2');
add1 = additionLayer(2,'Name','add1');
add2 = additionLayer(2,'Name','add2');
% 添加
lgraph = layerGraph();
lgraph = addLayers(lgraph,input1);
lgraph = addLayers(lgraph,input2);
lgraph = addLayers(lgraph,add1);
lgraph = addLayers(lgraph,add2);
% 连接
lgraph = connectLayers(lgraph,'input1','add1/in1');
lgraph = CBGLayer(lgraph,'input1','cbg1',3,channel1);
lgraph = CBGLayer(lgraph,'cbg1_gelu','cbg2',5,channel2);
lgraph = connectLayers(lgraph,'cbg2_gelu','add1/in2');
lgraph = HCOLayer(lgraph,'input2','add1','hco1',channel2);
lgraph = connectLayers(lgraph,'hco1_add','add2/in1');
lgraph = CBGLayer(lgraph,'hco1_add','cbg3',7,channel3);
lgraph = CBGLayer(lgraph,'cbg3_gelu','cbg4',9,channel4);
lgraph = connectLayers(lgraph,'cbg4_gelu','add2/in2');
lgraph = HCOLayer(lgraph,'input2','add2','hco2',channel4);
lgraph = FeedForwardNeural(lgraph,'input2','hco2_add','ffn',channel4);
end