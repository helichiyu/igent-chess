function X = HeatConductionOperator(X)
% 可调参数
k = 1;
t = 1;
% 获取输入的形状
[H, W, C, N] = size(X);
% 预计算频率权重（优化内存分配）
[cols, rows] = meshgrid(0:W-1, 0:H-1);
% 直接计算权重矩阵
weight = exp(-(rows.^2 + cols.^2) * k * t);  
% 合并通道和样本维度进行单层循环
for idx = 1:(C*N)
    % 直接在原数据上操作，避免临时变量
    channel = X(:,:,idx);
    channel = dct2(channel);% 2D DCT
    channel = channel .* weight;% 应用权重
    X(:,:,idx) = idct2(channel);% 2D IDCT
end
end