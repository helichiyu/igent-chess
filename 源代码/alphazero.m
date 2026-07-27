function alphazero(game)
close all; clc;
iterations = 1000;% 迭代次数
modelfile = 'model5.mat';
for iter = 1:iterations
    % 导入模型参数
    if isfile(modelfile)
        model = load(modelfile);
        net = model.net;
    else
        lgraph = chess1network();
        net = dlnetwork(lgraph);
    end
    tic; % 开始计时
    % 自我对弈生成数据
    if exist('ndata','var') == 0
        [sinput,ainput,poutput,voutput,ndata,vdata] = fselfplay(game,net,iter,iterations);
    else
        [sinput,ainput,poutput,voutput,ndata,vdata] = selfplay(game,net,iter,iterations,ndata,vdata);
    end
    toc; % 结束计时并显示耗时
    % 训练模型
    net = trainmodel(net,sinput,ainput,poutput,voutput);
    % 验证模型性能
    if isfile(modelfile)
        tic; % 开始计时
        if test(game,net,iter,iterations)
            save(modelfile,'net','-nocompression');
        end
        toc; % 结束计时并显示耗时
    else 
        save(modelfile,'net','-nocompression');
    end
end
end


function result = test(game,net,iter,iterations)
% 加载老模型
oldmodel = load('model5.mat');
oldnet = oldmodel.net;
victorious = 0;
% 进行多轮对局
rounds = 50;
for lun = 1:rounds
    % 展示迭代进度
    draw_progress_bar(iter,iterations,lun,rounds)
    winner = testgame(game,net,oldnet);
    if winner == 1
        victorious = victorious+1;
    elseif winner == 0
        victorious = victorious+0.5;
    end
    winner = testgame(game,oldnet,net);
    if winner == 2
        victorious = victorious+1;
    elseif winner == 0
        victorious = victorious+0.5;
    end
end
fprintf('\n');
% 判断是否可以替换
fprintf('victorious : %d\n',victorious);
win_rate = victorious / (2*rounds);  % 共2*rounds局
if win_rate > 0.5  % 设置合理阈值
    result = 1;
    disp('长江后浪推前浪')
else
    result = 0;
    disp('姜还是老的辣')
end
end


function winner = testgame(game,model1,model2)
% 2为平局，判断多少来回后为平局
winner = 0;draw = 50;

for d = 1:draw
    % 获取行动
    action = testdrop(game,model1);
    % 进行棋子移动
    game = move(game,action);
    % 判断游戏胜负
    if gameover(game)
        winner = 1;break;
    end
    game = shift(game);
    % 获取行动
    action = testdrop(game,model2);
    % 进行棋子移动
    game = move(game,action);
    % 判断游戏胜负
    if gameover(game)
        winner = 2;break;
    end
    game = shift(game);
end
end


function action = testdrop(game,net)
pieces = findOurPieces(game);
for i = 1:length(pieces(:,1))
    % 检查合法移动
    if isscalar(pieces(i,:))
        legalmove = ai_check(game,pieces);
    else
        legalmove = ai_check(game,pieces(i,:));
    end

    for j = 1:length(legalmove(:,1))
        % 构建移动矩阵
        step = [pieces(i,:),legalmove(j,:)];
        % 构建输入
        ingame = reshape(game,10,9,1,1);
        instep = reshape(step,4,1,1,1);
        % 进行预测
        Y = predict(net,ingame,instep);
        value = Y(2);
        % 判断选择的行动
        if exist('v', 'var') == 1
            if value > v
                v = value;
                action = step;
            end
        else
            v = value;
            action = step;
        end
    end
end
end


function net = trainmodel(net,sinput,ainput,poutput,voutput)
% 训练选项
options = trainingOptions('adam', ...
    'MaxEpochs',3, ...         % 训练轮数
    'MiniBatchSize',2048, ...     % 批大小
    'Shuffle','every-epoch', ...% 每轮数据打乱
    'LearnRateSchedule','exponential', ...
    'Verbose',false,...
    'LearnRateDropFactor',0.5, ...
    'LearnRateDropPeriod',1, ...
    'InitialLearnRate',0.0001);  % 初始学习率
% 设置数据储存
targets = [poutput,voutput];
ds_sinput = arrayDatastore(sinput,'IterationDimension',4);
ds_ainput = arrayDatastore(ainput,'IterationDimension',4);
ds_targets = arrayDatastore(targets,'IterationDimension',1);
% 组合数据存储
combinedDS = combine(ds_sinput, ds_ainput, ds_targets);
% 转换数据格式为网络需要的格式
transformedDS = transform(combinedDS, @(data) {data{1},data{2},data{3}});
% 训练模型
net = trainnet(transformedDS,net,"mse",options);
fprintf('\n');
end


function [sinput,ainput,poutput,voutput,ndata,vdata] = fselfplay(game,net,iter,iterations)
% 初始化数据字典
k = {game};ndata = dictionary(k,dictionary());vdata = dictionary(k,dictionary());
% 进行多轮自我对弈
rounds = 20000;
for l = 1:rounds
    % 展示迭代进度
    draw_progress_bar(iter,iterations,l,rounds)
    c = sqrt(2);
    [ndata,vdata] = onegame(game,net,ndata,vdata,c);
end
fprintf('\n');
% 生成训练数据
states = keys(ndata);sinput = [];ainput = [];poutput = [];voutput = [];
for i = 1:numel(states)
    k1 = states(i);nk = ndata(k1);ks = keys(nk);sumn = 0;vk = vdata(k1);
    % 计算之前已经选择了多少次
    for j = 1:length(ks)
        key = ks(j);
        value = nk(key);
        sumn = sumn + value;
    end
    % 分别添加数据
    for j = 1:length(ks)
        k2 = ks(j);s = k1{1};a = k2{1};
        s = reshape(s,10,9,1,1);a = reshape(a,4,1,1,1);
        sinput = cat(4,sinput,s);ainput = cat(4,ainput,a);
        p = nk(k2)/sumn;v = vk(k2)/nk(k2);
        p = reshape(p,1,1);v = reshape(v,1,1);
        poutput = cat(1,poutput,p);voutput = cat(1,voutput,v);
    end
end
end


function [sinput,ainput,poutput,voutput,ndata,vdata] = selfplay(game,net,iter,iterations,ndata,vdata)
% 进行多轮自我对弈
rounds = 100;
for l = 1:rounds
    % 展示迭代进度
    draw_progress_bar(iter,iterations,l,rounds)
    c = sqrt(2)*exp(-iter*0.04);
    [ndata,vdata] = onegame(game,net,ndata,vdata,c);
end
fprintf('\n');
% 生成训练数据
states = keys(ndata);sinput = [];ainput = [];poutput = [];voutput = [];
for i = 1:numel(states)
    k1 = states(i);nk = ndata(k1);ks = keys(nk);sumn = 0;vk = vdata(k1);
    % 计算之前已经选择了多少次
    for j = 1:length(ks)
        key = ks(j);
        value = nk(key);
        sumn = sumn + value;
    end
    % 分别添加数据
    for j = 1:length(ks)
        k2 = ks(j);s = k1{1};a = k2{1};
        s = reshape(s,10,9,1,1);a = reshape(a,4,1,1,1);
        sinput = cat(4,sinput,s);ainput = cat(4,ainput,a);
        p = nk(k2)/sumn;v = vk(k2)/nk(k2);
        p = reshape(p,1,1);v = reshape(v,1,1);
        poutput = cat(1,poutput,p);voutput = cat(1,voutput,v);
    end
end
end


function [ndata,vdata] = onegame(game,net,ndata,vdata,c)
% 2为平局，判断多少手后为平局
winner = 2;draw = 100;
% 预分配结构体内存
steps = repmat(struct('state',[],'action',[]),1,draw);

for d = 1:draw
    k1 = {game};
    % 将局面存入字典
    if ~isKey(ndata,k1)
        ndata(k1) = dictionary();
        vdata(k1) = dictionary();
    end
    % 获取行动
    action = drop(game,net,c,ndata,vdata,d);k2 = {action};
    % 将行动存入字典
    ndata = adddata(ndata,k1,k2,1);
    % 将局面行动对添加至结构体
    steps(d).state = k1;
    steps(d).action = k2;
    % 进行棋子移动
    game = move(game,action);
    % 判断游戏胜负并记录数据
    if gameover(game)
        winner = rem(d,2);
        states = {steps.state};actions = {steps.action};
        for i = 1:d
            r = winner==rem(i,2);
            r = r*2-1;
            r = r*0.9^(d-i);
            k1 = states{i};k2 = actions{i};
            vdata = adddata(vdata,k1,k2,r);
        end
        break;
    end
    game = shift(game);
end

% 是否平局
if winner == 2
    states = {steps.state};actions = {steps.action};
    r = 0;
    for i = 1:d
        k1 = states{i};k2 = actions{i};
        vdata = adddata(vdata,k1,k2,r);
    end
end
end


function map = adddata(map,k1,k2,r)
% 将局面存入字典
if ~isKey(map,k1)
    map(k1) = dictionary();
end
m = map(k1);
% 将数据存入字典
if m.numEntries == 0
    m(k2) = r;
else
    if isKey(m,k2)
        m(k2) = m(k2)+r;
    else
        m(k2) = r;
    end
end
map(k1) = m;
end


function action = drop(game,net,c,ndata,vdata,d)
% 找到我方棋子
pieces = findOurPieces(game);
% 初始化参数（s分数，k1元胞数组，sumn总选择次数，nk该局面对于的map）
k1 = {game};sumn = 0;nk = ndata(k1);vk = vdata(k1);
if nk.numEntries ~= 0
    ks = keys(nk);
    % 计算之前已经选择了多少次
    for i = 1:length(ks)
        key = ks{i};
        value = nk({key});
        sumn = sumn + value;
    end
end

for i = 1:length(pieces(:,1))
    % 检查合法移动
    if isscalar(pieces(i,:))
        legalmove = ai_check(game,pieces);
    else
        legalmove = ai_check(game,pieces(i,:));
    end
    
    if isempty(legalmove)
        continue
    end

    for j = 1:length(legalmove(:,1))
        % 构建移动矩阵
        step = [pieces(i,:),legalmove(j,:)];k2 = {step};
        % 构建输入
        ingame = reshape(game,10,9,1,1);
        instep = reshape(step,4,1,1,1);
        % 进行预测
        if isfile('model5.mat')
            if rem(d,2) == 1
                Y = predict(net,ingame,instep);
                p = Y(1);v = Y(2);
            else
                if nk.numEntries == 0
                    p = 0;v = 1;
                else
                    if isKey(nk,k2)
                        p = nk(k2)/sumn;
                        if vk.numEntries == 0
                            v = 1;
                        else
                            if isKey(vk,k2)
                                v = vk(k2)/nk(k2);
                            else
                                v = 0;
                            end
                        end
                    else
                        p = 0;v = 1;
                    end
                end
            end
        else
            p = rand;v = rand/10;
        end
        % 计算Polynomial Upper Confidence Trees公式
        if nk.numEntries == 0
            score = v;
        else
            if isKey(nk,k2)
                score = v + c*p*(sqrt(sumn)/(1+nk(k2)));
            else
                score = v + c*p*sqrt(sumn);
            end
        end
        % 判断选择的行动
        if exist('s', 'var') == 1
            if score > s
                s = score;
                action = step;
            end
        else
            s = score;
            action = step;
        end
    end
end
end


function flag = gameover(game)
% 检查矩阵中是否不存在同时出现的1和8
% 如果存在1和8同时出现，返回false；否则返回true
hasOne = any(game(:) == 1);  % 检查矩阵中是否有1
hasEight = any(game(:) == 8);  % 检查矩阵中是否有8
flag = ~(hasOne && hasEight);  % 如果不同时存在，返回true
end


function game = move(game,action)
[r0,c0,r,c] = deal(action(1),action(2),action(3),action(4));
chess = game(r0,c0);
game(r0,c0) = 0;game(r,c) = chess;
end


function pieces = findOurPieces(game)
% 创建掩码以识别1-7范围内的元素
mask = (game >= 1) & (game <= 7);
% 获取符合条件的元素坐标
[row,col] = find(mask);
% 组合行和列坐标为N×2的矩阵
pieces = [row,col];
end


function game = shift(game)
result = game;
% 创建掩码以识别不同范围的元素
mask8to14 = (result >= 8) & (result <= 14);
mask1to7 = (result >= 1) & (result <= 7);
% 根据掩码对元素进行相应的加减操作
game(mask8to14) = game(mask8to14) - 7;
game(mask1to7) = game(mask1to7) + 7;
game = rot90(game, 2);
end


function draw_progress_bar(iter, max_iter, lun, max_lun)
    % 进度条长度
    bar_length = 100;
    % 计算已完成和未完成的部分
    percent = lun/max_lun;
    completed = floor(percent * bar_length);
    remaining = bar_length - completed;
    % 构建进度条字符串
    bar = [repmat('=', 1, completed), repmat(' ', 1, remaining)];
    % 计算退格符数量（始终回到行首）
    str = sprintf('Iteration %d/%d : Rounds %d/%d |%s| %.1f%%', ...
              iter, max_iter, lun, max_lun, bar, percent*100);
    backspaces = repmat(sprintf('\b'), 1, length(str));
    % 输出进度条和迭代信息
    if lun ~= 1
        fprintf('%s', backspaces);
    end
    fprintf('%s',str);
end