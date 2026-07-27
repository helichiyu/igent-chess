function chess()
% 创建主窗口
fig = figure('Name','中国象棋', 'NumberTitle','off', 'Position',[850 150 500 500],...
    'MenuBar','none', 'WindowButtonDownFcn',@onClick);
ax = axes('Parent',fig, 'Position',[0.05 0.05 0.9 0.9],...
    'YDir','reverse', 'XLim',[0.5 9.5], 'YLim',[0.5 10.5],...
    'XTick',[], 'YTick',[], 'Box','on', 'Color',[0.94 0.90 0.80]);
hold(ax, 'on');
% 初始化菜单
menu_game = uimenu(fig,'Label','游戏');
uimenu(menu_game,'Label','开始游戏','Callback',@startGame);
menu_ai = uimenu(menu_game,'Label','人机对弈');
uimenu(menu_ai,'Label','红方','Callback',{@startAIGame,'red'});
uimenu(menu_ai,'Label','黑方','Callback',{@startAIGame,'black'});
% 初始化棋盘图形
[textHandles, rectHandles] = initBoardGraphics(ax);
% 初始化游戏数据
gameData = struct(...
    'currentBoard', zeros(10,9),...
    'selectedPos', [],...
    'selectedRect', [],...
    'currentPlayer', 'red',...
    'gameMode', 'start',...
    'aiColor', '',...
    'textHandles', textHandles,...
    'rectHandles', rectHandles,...
    'possibleMoves', []);
setappdata(fig, 'chessData', gameData);
end

% 初始化棋局
function [textHandles, rectHandles] = initBoardGraphics(ax)
% 初始化文本和矩形图形对象
textHandles = gobjects(10,9);
rectHandles = gobjects(10,9);
for x = 1:10
    for y = 1:9
        rectHandles(x,y) = rectangle(ax, 'Position',[y-0.5 x-0.5 1 1],...
            'FaceColor','none', 'EdgeColor','black');
        textHandles(x,y) = text(ax, y, x, '',...
            'HorizontalAlignment','center', 'FontSize',16, 'FontWeight','bold');
    end
end
end

% 开始游戏默认设置
function startGame(~,~)
fig = gcf;
gameData = getappdata(fig, 'chessData');
gameData.currentBoard = initBoard();
gameData.gameMode = 'start';
gameData.currentPlayer = 'red';
set(gca,'YDir','reverse');  % 默认红方在下
updateBoardDisplay(gameData);
setappdata(fig, 'chessData', gameData);
end

% 人机对弈默认设置
function startAIGame(~,~,userColor)
fig = gcf;
gameData = getappdata(fig, 'chessData');
gameData.currentBoard = initcanBoard();
gameData.gameMode = 'ai';
% 设置AI颜色为对方颜色
if strcmpi(userColor, 'red')
    gameData.aiColor = 'black';
else
    gameData.aiColor = 'red';
end
% 固定红方先手
gameData.currentPlayer = 'red';
updateBoardDisplay(gameData);
% 如果AI是红方（先手），立即执行AI移动
if strcmpi(gameData.aiColor, 'red')
    aimove = aiMove(gameData);
    gameData.currentBoard = change(gameData.currentBoard,aimove);
    updateBoardDisplay(gameData);
    drawnow;
    gameData.currentPlayer = togglePlayer(gameData.currentPlayer);
end
setappdata(fig, 'chessData', gameData);
end

% 中国象棋默认开局
function board = initBoard()
% 初始化棋盘布局
board = zeros(10,9);
% 红方棋子 (1-7)
board(10,:)   = [5 4 3 2 1 2 3 4 5]; % 车马相士将仕象马车
board(8,[2,8]) = 6;                   % 炮
board(7,:)   = [7 0 7 0 7 0 7 0 7];   % 兵
% 黑方棋子 (8-14)
board(1,:)   = [12 11 10 9 8 9 10 11 12];
board(3,[2,8]) = 13;
board(4,:)   = [14 0 14 0 14 0 14 0 14];
end

% 残局开局
function board = initcanBoard()
% 初始化棋盘布局
board = [
    0 ,0 ,0 ,0 ,12,8 ,0 ,0 ,0 ;
    0 ,0 ,0 ,7 ,0 ,0 ,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,10,7 ,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,0 ,0 ,0 ,0 ,7 ;
    0 ,14,0 ,0 ,14,0 ,0 ,6 ,0 ;
    0 ,0 ,0 ,14,0 ,14,0 ,0 ,0 ;
    0 ,0 ,0 ,0 ,1 ,0 ,5 ,5 ,0 ;
    ];
end

% 游戏进行中
function onClick(~,~)
fig = gcf;
gameData = getappdata(fig, 'chessData');
ax = gca;
% 获取点击位置（注意坐标系转换）
pt = get(ax, 'CurrentPoint');
clickY = round(pt(1,1));  % 列号对应矩阵第二维
clickX = round(pt(1,2));  % 行号对应矩阵第一维
% 坐标有效性检查
if clickX<1 || clickX>10 || clickY<1 || clickY>9, return; end
% 阶段判断：选择棋子或移动棋子
if isempty(gameData.selectedPos)
    % ===== 选择棋子阶段 =====
    selectedPiece = gameData.currentBoard(clickX, clickY);
    % 有效性检查：空位或对方棋子
    if selectedPiece == 0 || ~isValidSelection(selectedPiece, gameData.currentPlayer)
        return;
    end
    % 获取并显示合法移动
    gameData.selectedPos = [clickX, clickY];
    gameData.possibleMoves = ai_check(gameData.currentBoard, gameData.selectedPos);
    updateMoveDots(gameData);  % 更新白点显示
    % 高亮当前选中格子（黄色半透明）
    set(gameData.rectHandles(clickX,clickY),...
        'FaceColor',[1 1 0 0.3],...
        'EdgeColor','black');
    setappdata(fig, 'chessData', gameData);
else
    % ===== 移动棋子阶段 =====
    [srcX, srcY] = deal(gameData.selectedPos(1), gameData.selectedPos(2));
    % 情况1：点击同一棋子 → 取消选择
    if isequal([srcX, srcY], [clickX, clickY])
        set(gameData.rectHandles(srcX,srcY), 'FaceColor','none');
        clearMoveDots();
        gameData.selectedPos = [];
        setappdata(fig, 'chessData', gameData);
        return;
    end
    % 情况2：点击合法位置 → 执行移动
    if any(ismember(gameData.possibleMoves, [clickX, clickY], 'rows'))
        % 执行棋子移动
        gameData.currentBoard(clickX, clickY) = gameData.currentBoard(srcX, srcY);
        gameData.currentBoard(srcX, srcY) = 0;
        % 强制刷新界面
        updateBoardDisplay(gameData);
        drawnow; % 立即刷新图形
        % 清除状态
        set(gameData.rectHandles(srcX,srcY), 'FaceColor','none');
        clearMoveDots();
        drawnow;
        gameData.selectedPos = [];
        % 切换玩家
        gameData.currentPlayer = togglePlayer(gameData.currentPlayer);
        setappdata(fig, 'chessData', gameData);
        if strcmp(gameData.gameMode,'ai')
            aimove = aiMove(gameData);
            gameData.currentBoard = change(gameData.currentBoard,aimove);
            updateBoardDisplay(gameData);
            drawnow;
            gameData.currentPlayer = togglePlayer(gameData.currentPlayer);
            setappdata(fig, 'chessData', gameData);
        end
        % 情况3：点击非法位置 → 保持当前选择状态
    else
        warndlg('请选择合法移动位置！','提示');
        return;
    end
end
end

% 绘制当前棋局
function updateBoardDisplay(gameData)
pieces = {'帅','士','相','马','车','炮','兵','将','仕','象','馬','車','砲','卒'};
colors = {'red','red','red','red','red','red','red',...
    [0 0.5 0],[0 0.5 0],[0 0.5 0],[0 0.5 0],[0 0.5 0],[0 0.5 0],[0 0.5 0]};

for x = 1:10
    for y = 1:9
        piece = gameData.currentBoard(x,y);
        if piece > 0
            set(gameData.textHandles(x,y),...
                'String',pieces{piece},...
                'Color',colors{piece});
        else
            set(gameData.textHandles(x,y), 'String','');
        end
    end
end
drawnow;
end

% 更新白点显示（可选修改，移除句柄跟踪）
function updateMoveDots(gameData)
clearMoveDots(); % 先清除所有现有白点
fig = gcf;
ax = findobj(fig, 'Type','axes');
% 绘制新白点
for i = 1:size(gameData.possibleMoves,1)
    pos = gameData.possibleMoves(i,:);
    scatter(ax, pos(2), pos(1), 120, 'o',...
        'MarkerFaceColor','w',...
        'MarkerEdgeColor',[0.3 0.3 0.3],...
        'LineWidth',1.5);
end
drawnow;
end

% 清除白点
function clearMoveDots()
fig = gcf;
ax = findobj(fig, 'Type','axes');
% 查找所有白色圆点的散点图对象
dots = findobj(ax, 'Type','scatter', 'MarkerFaceColor','w', 'MarkerEdgeColor', [0.3 0.3 0.3]);
if ~isempty(dots)
    delete(dots);
end
drawnow;
end

%人机选择移动
function move = aiMove(gameData)
% 初始化
model = load('model5.mat');
net = model.net;
board = gameData.currentBoard;
aicolor = gameData.aiColor;
% 根据当前玩家转换棋盘
if strcmp(aicolor, 'black')
    result = board;
    % 创建掩码以识别不同范围的元素
    mask8to14 = (result >= 8) & (result <= 14);
    mask1to7 = (result >= 1) & (result <= 7);
    % 根据掩码对元素进行相应的加减操作
    board(mask8to14) = board(mask8to14) - 7;
    board(mask1to7) = board(mask1to7) + 7;
    board = rot90(board, 2);
end
% 创建掩码以识别1-7范围内的元素
mask = (board >= 1) & (board <= 7);
% 获取符合条件的元素坐标
[row,col] = find(mask);
% 组合行和列坐标为N×2的矩阵
pieces = [row,col];

for i = 1:length(pieces(:,1))
    % 检查合法移动
    if isscalar(pieces(i,:))
        legalmove = ai_check(board,pieces);
    else
        legalmove = ai_check(board,pieces(i,:));
    end

    for j = 1:length(legalmove(:,1))
        % 构建移动矩阵
        step = [pieces(i,:),legalmove(j,:)];
        % 构建输入
        ingame = reshape(board,10,9,1,1);
        instep = reshape(step,4,1,1,1);
        % 进行预测
        Y = predict(net,ingame,instep);
        value = Y(2);
        % 判断选择的行动
        if exist('v', 'var') == 1
            if value > v
                v = value;
                move = step;
            end
        else
            v = value;
            move = step;
        end
    end
end
if strcmp(aicolor, 'black')
    move = [11-move(1),10-move(2),11-move(3),10-move(4)];
end
end

% 判断是否是当前玩家的棋子
function valid = isValidSelection(pieceValue, currentPlayer)
% 数值范围判断提升效率
if currentPlayer == "red"
    valid = pieceValue >= 1 & pieceValue <= 7;
else
    valid = pieceValue >= 8 & pieceValue <= 14;
end
end

% 切换当前玩家
function player = togglePlayer(currentPlayer)
if strcmpi(currentPlayer, 'red')
    player = 'black';
else
    player = 'red';
end
end

% 根据移动更改棋局
function board = change(board,move)
r0 = move(1);c0 = move(2);r1 = move(3);c1 = move(4);
chess_math = board(r0,c0);
board(r0,c0) = 0;board(r1,c1) = chess_math;
end