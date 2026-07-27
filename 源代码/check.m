function action = check(game,index)
% 获取棋子种类
r = index(1);
c = index(2);
chess = game(r,c);
% 将帅
if chess == 1 || chess == 8
    A = [r+1,c;r,c+1;r-1,c;r,c-1];
% 士仕
elseif chess == 2 || chess == 9
    A = [r+1,c+1;r-1,c+1;r-1,c-1;r+1,c-1];
% 象相
elseif chess == 3 || chess == 10
    % 在棋盘内的象脚
    B = [r+1, c+1; r-1, c+1; r-1, c-1; r+1, c-1];
    valid_indices = (B(:,1) >= 1 & B(:,1) <= 10) & ...
        (B(:,2) >= 1 & B(:,2) <= 9);
    valid_B = B(valid_indices, :);
    % 没被绊的象脚位置
    game_values = zeros(size(valid_B, 1), 1);
    for i = 1:size(valid_B, 1)
        game_values(i) = game(valid_B(i,1), valid_B(i,2));
    end
    zero_indices = (game_values == 0);
    valid_zero_B = valid_B(zero_indices, :);
    % 可以走的位置
    if ~isempty(valid_zero_B)
        A = [valid_zero_B(:,1)*2 - r, valid_zero_B(:,2)*2 - c];
    else
        A = [];
    end
% 马馬
elseif chess == 4 || chess == 11
    % 在棋盘内的马脚
    B = [r+1,c;r,c+1;r-1,c;r,c-1];
    valid_indices = (B(:,1) >= 1 & B(:,1) <= 10) & ...
        (B(:,2) >= 1 & B(:,2) <= 9);
    valid_B = B(valid_indices, :);
    % 没被绊的马脚位置
    game_values = zeros(size(valid_B, 1), 1);
    for i = 1:size(valid_B, 1)
        game_values(i) = game(valid_B(i,1), valid_B(i,2));
    end
    zero_indices = (game_values == 0);
    valid_zero_B = valid_B(zero_indices, :);
    % 可以走的位置，横向
    A = [];
    dr = valid_zero_B(:,1) - r;
    zero_dr_indices = (dr == 0);
    if any(zero_dr_indices)
        zero_dr_points = valid_zero_B(zero_dr_indices, :);
        num_zero_dr = size(zero_dr_points, 1);
        vertical_moves = zeros(2*num_zero_dr, 2);
        vertical_moves(1:2:end, :) = [r+1, zero_dr_points(:,2)*2 - c];
        vertical_moves(2:2:end, :) = [r-1, zero_dr_points(:,2)*2 - c];
        A = vertical_moves;
    end
    % 纵向
    non_zero_dr_indices = ~zero_dr_indices;
    if any(non_zero_dr_indices)
        non_zero_dr_points = valid_zero_B(non_zero_dr_indices, :);
        num_non_zero_dr = size(non_zero_dr_points, 1);
        horizontal_moves = zeros(2*num_non_zero_dr, 2);
        horizontal_moves(1:2:end, :) = [non_zero_dr_points(:,1)*2 - r, c+1];
        horizontal_moves(2:2:end, :) = [non_zero_dr_points(:,1)*2 - r, c-1];
        if isempty(A)
            A = horizontal_moves;
        else
            A = [A; horizontal_moves];
        end
    end
% 车車
elseif chess == 5 || chess == 12
    % 提取四个方向的向量
    left   = flip(game(r, 1:c-1));
    right  = game(r, c+1:9);
    up     = flip(game(1:r-1, c));
    down   = game(r+1:10, c);
    % 计算各方向第一个非零位置
    j_left  = find(left ~= 0, 1, 'first');
    j_right = find(right ~= 0, 1, 'first');
    j_up    = find(up ~= 0, 1, 'first');
    j_down  = find(down ~= 0, 1, 'first');
    % 处理全零向量的情况
    if isempty(j_left),  j_left  = length(left);  end
    if isempty(j_right), j_right = length(right); end
    if isempty(j_up),    j_up    = length(up);    end
    if isempty(j_down),  j_down  = length(down);  end
    % 生成各方向的坐标矩阵
    if j_left > 0
        A1 = [r*ones(j_left,1), (c-1:-1:c-j_left)'];
    else
        A1 = [];
    end

    if j_right > 0
        A2 = [r*ones(j_right,1), (c+1:c+j_right)'];
    else
        A2 = [];
    end

    if j_up > 0
        A3 = [(r-1:-1:r-j_up)', c*ones(j_up,1)];
    else
        A3 = [];
    end

    if j_down > 0
        A4 = [(r+1:r+j_down)', c*ones(j_down,1)];
    else
        A4 = [];
    end

    % 合并结果
    A = [A1; A2; A3; A4];
% 炮
elseif chess == 6 || chess == 13
    % 提取四个方向的向量
    left   = flip(game(r, 1:c-1));
    right  = game(r, c+1:9);
    up     = flip(game(1:r-1, c));
    down   = game(r+1:10, c);
    % 计算各方向两个非零位置
    j_left  = find(left ~= 0, 2, 'first');
    j_right = find(right ~= 0, 2, 'first');
    j_up    = find(up ~= 0, 2, 'first');
    j_down  = find(down ~= 0, 2, 'first');
    % 处理全零向量的情况
    if isempty(j_left),  j_left  = [length(left)];  end
    if isempty(j_right), j_right = [length(right)]; end
    if isempty(j_up),    j_up    = [length(up)];    end
    if isempty(j_down),  j_down  = [length(down)];  end
    % 生成各方向的坐标矩阵
    if length(j_left) == 2
        j1 = j_left(1) - 1;
        A1 = [r*ones(j1,1), (c-1:-1:c-j1)';r,c-j_left(2)];
    elseif isscalar(j_left)
        j1 = j_left(1) - 1;
        A1 = [r*ones(j1,1), (c-1:-1:c-j1)'];
    else
        A1 = [];
    end

    if length(j_right) == 2
        j2 = j_right(1) - 1;
        A2 = [r*ones(j2,1), (c+1:c+j2)';r,c+j_right(2)];
    elseif isscalar(j_right)
        j2 = j_right(1) - 1;
        A1 = [r*ones(j2,1), (c+1:c+j2)'];
    else
        A2 = [];
    end

    if length(j_up) == 2
        j3 = j_up(1)-1;
        A3 = [(r-1:-1:r-j3)', c*ones(j3,1);r-j_up(2),c];
    elseif isscalar(j_up)
        j3 = j_up(1)-1;
        A3 = [(r-1:-1:r-j3)', c*ones(j3,1)];
    else
        A3 = [];
    end

    if length(j_down) == 2
        j4 = j_down(1)-1;
        A4 = [(r+1:r+j4)', c*ones(j4,1);r+j_down(2),c];
    elseif isscalar(j_down)
        j4 = j_down(1)-1;
        A4 = [(r+1:r+j4)', c*ones(j4,1)];
    else
        A3 = [];
    end
    % 合并结果
    A = [A1; A2; A3; A4];
% 兵
elseif chess == 7
    if r>5
        A = [r-1,c];
    else
        A = [r-1,c;r,c-1;r,c+1];
    end
% 卒
elseif chess == 14
    if r<6
        A = [r+1,c];
    else
        A = [r+1,c;r,c-1;r,c+1];
    end
end
%筛选棋子落在棋盘内
if chess == 1 || chess == 2
    condition = (A(:,1) >= 8) & (A(:,1) <= 10) & ...
        (A(:,2) >= 4) & (A(:,2) <= 6);
elseif chess == 8 || chess == 9
    condition = (A(:,1) >= 1) & (A(:,1) <= 3) & ...
        (A(:,2) >= 4) & (A(:,2) <= 6);
elseif chess == 3
    condition = (A(:,1) >= 6) & (A(:,1) <= 10) & ...
        (A(:,2) >= 1) & (A(:,2) <= 9);
elseif chess == 10
    condition = (A(:,1) >= 1) & (A(:,1) <= 2) & ...
        (A(:,2) >= 1) & (A(:,2) <= 9);
else
    condition = (A(:,1) >= 1) & (A(:,1) <= 10) & ...
        (A(:,2) >= 1) & (A(:,2) <= 9);
end
%筛选落点不是我方棋子
A = A(condition, :);
rows = 1:size(A, 1);
game_values = zeros(size(rows));
for i = rows
    game_values(i) = game(A(i,1), A(i,2));
end
condition1 = (chess < 8) & (game_values > 7);
condition2 = (chess > 7) & (game_values < 8);
condition3 = (game_values == 0);
valid_indices = rows(condition1 | condition2 | condition3);
action = A(valid_indices, :);
end