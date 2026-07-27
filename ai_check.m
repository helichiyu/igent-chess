function [action] = ai_check(game, index)
    [r, c] = deal(index(1), index(2));
    chess = game(r, c);
    color = chess < 8; % 红方为true
    
    % 预定义棋盘常量
    [ROWS, COLS] = deal(10, 9);
    moves = zeros(28, 2); % 预分配最大可能移动数
    count = 0;
    
    switch chess
        case {1, 8} % 将帅
            dirs = [1,0; 0,1; -1,0; 0,-1];
            candidate = [r c] + dirs;
            if chess == 1 % 红将
                valid = candidate(:,1)>=8 & candidate(:,1)<=10 & ...
                        candidate(:,2)>=4 & candidate(:,2)<=6;
            else % 黑帅
                valid = candidate(:,1)>=1 & candidate(:,1)<=3 & ...
                        candidate(:,2)>=4 & candidate(:,2)<=6;
            end
            [moves, count] = add_valid_moves(moves, count, candidate(valid,:));
            
        case {2, 9} % 士仕
            dirs = [1,1; -1,1; -1,-1; 1,-1];
            candidate = [r c] + dirs;
            if chess == 2 % 红士
                valid = candidate(:,1)>=8 & candidate(:,1)<=10 & ...
                        candidate(:,2)>=4 & candidate(:,2)<=6;
            else % 黑仕
                valid = candidate(:,1)>=1 & candidate(:,1)<=3 & ...
                        candidate(:,2)>=4 & candidate(:,2)<=6;
            end
            [moves, count] = add_valid_moves(moves, count, candidate(valid,:));

        case {3, 10} % 象相
            steps = [2,2; 2,-2; -2,2; -2,-2];
            candidate = [r c] + steps;
            mid_points = [r c] + steps/2;

            valid_mid_pos = (mid_points(:,1) >= 1 & mid_points(:,1) <= 10) & ...
                (mid_points(:,2) >= 1 & mid_points(:,2) <= 9);
            valid_mid = false(size(mid_points,1),1);
            valid_mid(valid_mid_pos) = game(sub2ind([10,9],...
                mid_points(valid_mid_pos,1),...
                mid_points(valid_mid_pos,2))) == 0;

            valid_candidate = (candidate(:,1) >= 1 & candidate(:,1) <= 10) & ...
                (candidate(:,2) >= 1 & candidate(:,2) <= 9);

            if chess == 3 % 红相
                valid = valid_mid & valid_candidate & (candidate(:,1) >= 6);
            else % 黑象
                valid = valid_mid & valid_candidate & (candidate(:,1) <= 5);
            end

            [moves, count] = add_valid_moves(moves, count, candidate(valid,:));

        case {4, 11} % 马
            jumps = [1,2; 2,1; -1,2; 2,-1; 1,-2; -2,1; -1,-2; -2,-1];
            candidate = [r c] + jumps;

            is_row_jump = abs(jumps(:,1)) == 2;
            leg_r = r + is_row_jump .* sign(jumps(:,1));
            leg_c = c + (~is_row_jump) .* sign(jumps(:,2));

            valid_leg_pos = leg_r >= 1 & leg_r <= ROWS & ...
                leg_c >= 1 & leg_c <= COLS;
            valid_leg = false(size(leg_r));
            valid_leg(valid_leg_pos) = game(sub2ind([ROWS,COLS],...
                leg_r(valid_leg_pos),...
                leg_c(valid_leg_pos))) == 0;

            valid_move = candidate(:,1) >= 1 & candidate(:,1) <= ROWS & ...
                candidate(:,2) >= 1 & candidate(:,2) <= COLS;
            [moves, count] = add_valid_moves(moves, count, candidate(valid_leg & valid_move,:));

        case {5, 12} % 车
            dirs = [0,1; 1,0; 0,-1; -1,0];
            for d = dirs'
                line = get_vector_moves(game, r, c, d, color);
                [moves, count] = buffer_append(moves, count, line);
            end
            
        case {6, 13} % 炮
            dirs = [0,1; 1,0; 0,-1; -1,0];
            for d = dirs'
                line = get_cannon_moves(game, r, c, d, color);
                [moves, count] = buffer_append(moves, count, line);
            end
            
        case 7 % 红兵
            base_dirs = [-1,0];
            if r <= 5
                dirs = [base_dirs; 0,1; 0,-1];
            else
                dirs = base_dirs;
            end
            candidate = [r c] + dirs;
            valid = all(candidate >= [1 1],2) & all(candidate <= [ROWS COLS],2);
            [moves, count] = add_valid_moves(moves, count, candidate(valid,:));
            
        case 14 % 黑卒
            base_dirs = [1,0];
            if r >= 6
                dirs = [base_dirs; 0,1; 0,-1];
            else
                dirs = base_dirs;
            end
            candidate = [r c] + dirs;
            valid = all(candidate >= [1 1],2) & all(candidate <= [ROWS COLS],2);
            [moves, count] = add_valid_moves(moves, count, candidate(valid,:));
    end
    
    if count > 0
        targets = game(sub2ind([ROWS,COLS], moves(1:count,1), moves(1:count,2)));
        valid = (targets == 0) | ( (color & targets>7) | (~color & targets<8) );
        moves(1:sum(valid),:) = moves(valid,:);
        count = sum(valid);
    end
    
    % 过滤导致将帅照面的移动（修复版）
    if count > 0
        valid_actions = true(count, 1); % 初始化为全部有效
        for i = 1:count
            sim_board = game;
            target_r = moves(i,1);
            target_c = moves(i,2);
            
            % 更新模拟棋盘
            sim_board(r, c) = 0;
            sim_board(target_r, target_c) = chess;
            
            % 检查是否导致将帅照面
            if check_face_to_face(sim_board)
                valid_actions(i) = false;
            end
        end
        % 应用过滤
        moves = moves(1:count, :); % 确保只考虑有效部分
        moves = moves(valid_actions, :);
        count = size(moves, 1);
    end
    
    action = moves(1:count, :);
end

% 修复的将帅照面检查函数
function flag = check_face_to_face(board)
    % 找到红将(1)和黑帅(8)的位置
    [red_r, red_c] = find(board == 1, 1, 'first');
    [black_r, black_c] = find(board == 8, 1, 'first');
    
    % 如果缺少将或帅，则不会照面
    if isempty(red_r) || isempty(black_r)
        flag = false;
        return;
    end
    
    % 检查是否在同一列
    if red_c ~= black_c
        flag = false;
        return;
    end
    
    col = red_c;
    % 确保黑帅在红将上方（行号更小）
    if black_r >= red_r
        flag = false;
        return;
    end
    
    % 检查中间是否有棋子（从黑帅下方一行到红将上方一行）
    for r = (black_r + 1):(red_r - 1)
        if board(r, col) ~= 0
            flag = false; % 有棋子遮挡
            return;
        end
    end
    
    flag = true; % 将帅照面
end

% 向量化路径生成（车）
function line = get_vector_moves(game, r, c, d, color)
    [ROWS, COLS] = size(game);
    max_step = (d(1) ~= 0) * ( (ROWS - r)*(d(1)==1) + (r-1)*(d(1)==-1) ) + ...
                (d(2) ~= 0) * ( (COLS - c)*(d(2)==1) + (c-1)*(d(2)==-1) );
    if max_step == 0
        line = zeros(0,2);
        return
    end
    
    steps = (1:max_step)';
    path = [r + d(1)*steps, c + d(2)*steps];
    
    % 批量检查路径
    idx = sub2ind([ROWS,COLS], path(:,1), path(:,2));
    values = game(idx);
    
    obstacle = find(values ~= 0, 1);
    if ~isempty(obstacle)
        valid = 1:obstacle;
        if (color && values(obstacle)>7) || (~color && values(obstacle)<8)
            line = path(valid,:);
        else
            line = path(1:obstacle-1,:);
        end
    else
        line = path;
    end
end

function line = get_cannon_moves(game, r, c, d, color)
    % 沿方向d遍历所有可能的位置
    [ROWS, COLS] = size(game);
    line = [];
    current_r = r;
    current_c = c;
    obstacle_found = false;
    
    while true
        current_r = current_r + d(1);
        current_c = current_c + d(2);
        
        % 边界检查
        if current_r < 1 || current_r > ROWS || current_c < 1 || current_c > COLS
            break;
        end
        
        pos = [current_r, current_c];
        piece = game(current_r, current_c);
        
        if ~obstacle_found
            if piece == 0
                line = [line; pos]; % 空位可移动
            else
                obstacle_found = true; % 发现障碍物
            end
        else
            if piece ~= 0
                % 检查是否为敌方棋子
                if (color && piece >= 8) || (~color && piece <=7)
                    line = [line; pos]; % 可跳跃攻击
                end
                break; % 无论敌我，遇到棋子即停止
            end
        end
    end
end

% 缓冲区追加函数
function [buffer, cnt] = buffer_append(buffer, cnt, new_items)
    if isempty(new_items)
        return
    end
    n = size(new_items,1);
    if cnt + n > size(buffer,1)
        buffer = [buffer; zeros(2*size(buffer,1), 2)]; % 动态扩展策略
    end
    buffer(cnt+1:cnt+n,:) = new_items;
    cnt = cnt + n;
end

% 有效移动添加函数
function [buffer, cnt] = add_valid_moves(buffer, cnt, new_items)
    if isempty(new_items)
        return
    end
    n = size(new_items,1);
    if cnt + n > size(buffer,1)
        buffer = [buffer; zeros(2*size(buffer,1), 2)]; % 动态扩展
    end
    buffer(cnt+1:cnt+n,:) = new_items;
    cnt = cnt + n;
end