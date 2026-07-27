function chess_gui()
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
        'possibleMoves', [],...
        'dotHandles', []);
    setappdata(fig, 'chessData', gameData);

    % ============== 嵌套函数定义开始 ==============
    
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

    function startGame(~,~)
        fig = gcf;
        gameData = getappdata(fig, 'chessData');
        gameData.currentBoard = initBoard();
        gameData.gameMode = 'start';
        gameData.currentPlayer = 'red';
        set(gca,'YDir','reverse');  % 默认红方在下
        updateBoardDisplay(gameData); % 调用嵌套函数
        setappdata(fig, 'chessData', gameData);
    end
    
    function startAIGame(~,~,userColor)
        fig = gcf;
        gameData = getappdata(fig, 'chessData');
        gameData.currentBoard = initBoard();
        gameData.gameMode = 'ai';
        
        % 设置AI颜色为对方颜色
        if strcmpi(userColor, 'red')
            gameData.aiColor = 'black';
        else
            gameData.aiColor = 'red';
        end
        
        gameData.currentPlayer = 'red'; % 固定红方先手
        
        % 调整棋盘显示方向
        ax = findobj(fig,'Type','axes');
        if strcmpi(userColor, 'black')
            set(ax,'YDir','normal');   % 黑方在下
        else
            set(ax,'YDir','reverse');  % 红方在下
        end
        
        updateBoardDisplay(gameData);
        setappdata(fig, 'chessData', gameData);
        
        % 如果AI是红方（先手），立即执行AI移动
        if strcmpi(gameData.aiColor, 'red')
            aiMove();
        end
    end

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

        % 人机模式判断当前是否AI回合
        if strcmp(gameData.gameMode, 'ai') && strcmp(gameData.currentPlayer, gameData.aiColor)
            return;
        end

        % 阶段判断：选择棋子或移动棋子
        if isempty(gameData.selectedPos)
            % ===== 选择棋子阶段 =====
            selectedPiece = gameData.currentBoard(clickX, clickY);

            % 有效性检查：空位或对方棋子
            if selectedPiece == 0 || ~isValidSelection(selectedPiece, gameData.currentPlayer)
                return;
            end

            % 清除之前可能存在的白点
            clearMoveDots();

            % 获取并显示合法移动
            gameData.selectedPos = [clickX, clickY];
            gameData.possibleMoves = ai_check(gameData.currentBoard, gameData.selectedPos);
            updateMoveDots(gameData);  % 更新白点显示

            % 高亮当前选中格子（黄色半透明）
            set(gameData.rectHandles(clickX,clickY),...
                'FaceColor',[1 1 0 0.3],...
                'EdgeColor','black');

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
                % ==== 关键修复：确保移动后立即更新 ====
                % 执行棋子移动
                gameData.currentBoard(clickX, clickY) = gameData.currentBoard(srcX, srcY);
                gameData.currentBoard(srcX, srcY) = 0;

                % 强制刷新界面
                updateBoardDisplay(gameData);
                drawnow; % 立即刷新图形

                % 清除状态
                set(gameData.rectHandles(srcX,srcY), 'FaceColor','none');
                clearMoveDots();
                gameData.selectedPos = [];

                % 切换玩家
                gameData.currentPlayer = togglePlayer(gameData.currentPlayer);

                % AI回合处理
                if strcmp(gameData.gameMode, 'ai')
                    pause(0.5);
                    performAIMove();
                end

                % 情况3：点击非法位置 → 保持当前选择状态
            else
                warndlg('请选择合法移动位置！','提示');
                return;
            end
        end

        % 更新全局数据
        setappdata(fig, 'chessData', gameData);

        % 胜利条件检查
        checkWinCondition(gameData);
    end
    
    function checkWinCondition(gameData)
        if ~any(gameData.currentBoard == 1) % 红将消失
            msgbox('黑方胜利！');
        elseif ~any(gameData.currentBoard == 8) % 黑将消失
            msgbox('红方胜利！');
        end
    end

    function performAIMove()
        fig = gcf;
        gameData = getappdata(fig, 'chessData');

        % 清除任何残留状态
        clearMoveDots();
        if ~isempty(gameData.selectedPos)
            set(gameData.rectHandles(gameData.selectedPos(1),gameData.selectedPos(2)),...
                'FaceColor','none');
            gameData.selectedPos = [];
        end

        % 生成AI移动
        move = aiMove(gameData.currentBoard, gameData.currentPlayer);

        if ~isempty(move)
            % 解析移动坐标
            srcX = move(1);
            srcY = move(2);
            destX = move(3);
            destY = move(4);

            % 执行移动
            gameData.currentBoard(destX, destY) = gameData.currentBoard(srcX, srcY);
            gameData.currentBoard(srcX, srcY) = 0;

            % 切换玩家并更新显示
            gameData.currentPlayer = togglePlayer(gameData.currentPlayer);
            updateBoardDisplay(gameData);
            setappdata(fig, 'chessData', gameData);

            % 新增：胜利条件检查
            checkWinCondition(gameData);
        end
    end

    function valid = isValidSelection(pieceValue, currentPlayer)
        % 数值范围判断提升效率
        if currentPlayer == "red"
            valid = pieceValue >= 1 & pieceValue <= 7;
        else
            valid = pieceValue >= 8 & pieceValue <= 14;
        end
    end

    function player = togglePlayer(currentPlayer)
        % 切换当前玩家
        if strcmpi(currentPlayer, 'red')
            player = 'black';
        else
            player = 'red';
        end
    end

% --- 新增函数：更新合法移动白点 ---
    function updateMoveDots(gameData)
        % 清除旧白点
        if ~isempty(gameData.dotHandles)
            arrayfun(@delete, gameData.dotHandles);
        end

        % 绘制新白点（需转换坐标系）
        fig = gcf;
        ax = findobj(fig, 'Type','axes');
        dotHandles = gobjects(size(gameData.possibleMoves,1),1);
        for i = 1:size(gameData.possibleMoves,1)
            pos = gameData.possibleMoves(i,:);
            % 注意：图形坐标与矩阵坐标转换（Y轴方向）
            dotHandles(i) = scatter(ax, pos(2), pos(1), 120, 'o',...
                'MarkerFaceColor','w',...
                'MarkerEdgeColor',[0.3 0.3 0.3],...
                'LineWidth',1.5);
        end
        gameData.dotHandles = dotHandles;
        setappdata(fig, 'chessData', gameData);
    end

    function clearMoveDots()
        fig = gcf;
        gameData = getappdata(fig, 'chessData');
        if ~isempty(gameData.dotHandles)
            delete([gameData.dotHandles]); % 删除所有白点图形对象
            gameData.dotHandles = [];
            setappdata(fig, 'chessData', gameData);
        end
    end

    function updateBoardDisplay(gameData) % 正确定义为嵌套函数
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

end

function move = aiMove(board, currentPlayer)
    % 根据当前玩家筛选棋子
    if strcmp(currentPlayer, 'red')
        [rows, cols] = find(board >= 1 & board <=7);
    else
        [rows, cols] = find(board >=8 & board <=14);
    end
    maxPossible = 200; % 根据棋盘状态预估
    allMoves = zeros(maxPossible, 4);
    count = 0;
    
    for i = 1:length(rows)
        r = rows(i); 
        c = cols(i);
        possible = ai_check(board, [r,c]);
        if ~isempty(possible)
            n = size(possible,1);
            if count + n > maxPossible
                % 动态扩展数组
                allMoves = [allMoves; zeros(200,4)];
                maxPossible = maxPossible + 200;
            end
            allMoves(count+1:count+n, :) = [repmat([r c], n, 1), possible];
            count = count + n;
        end
    end
    
    % 随机选择合法移动
    if count > 0
        move = allMoves(randi(count), :);
    else
        move = [];
    end
end