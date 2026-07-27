function targets = pseudo_moves_for_piece(board, row, col)
%PSEUDO_MOVES_FOR_PIECE Generate movement-rule targets, including captures.
piece = board(row, col);
if piece == 0
    targets = zeros(0, 2);
    return;
end
isRed = piece <= 7;
type = piece - 7 * (~isRed);
targets = zeros(0, 2);
switch type
    case 1
        steps = [1 0; -1 0; 0 1; 0 -1];
        candidates = [row col] + steps;
        if isRed
            inPalace = candidates(:, 1) >= 8 & candidates(:, 1) <= 10;
        else
            inPalace = candidates(:, 1) >= 1 & candidates(:, 1) <= 3;
        end
        inPalace = inPalace & candidates(:, 2) >= 4 & candidates(:, 2) <= 6;
        targets = candidates(inPalace, :);
        % A general can capture the opposing general along an open file.
        enemyKing = 8;
        if ~isRed, enemyKing = 1; end
        rows = find(board(:, col) ~= 0);
        rows(rows == row) = [];
        if ~isempty(rows)
            [~, nearest] = min(abs(rows - row));
            kingRow = rows(nearest);
            if board(kingRow, col) == enemyKing
                targets = [targets; kingRow col];
            end
        end
    case 2
        candidates = [row col] + [1 1; 1 -1; -1 1; -1 -1];
        if isRed
            valid = candidates(:, 1) >= 8 & candidates(:, 1) <= 10;
        else
            valid = candidates(:, 1) >= 1 & candidates(:, 1) <= 3;
        end
        valid = valid & candidates(:, 2) >= 4 & candidates(:, 2) <= 6;
        targets = candidates(valid, :);
    case 3
        steps = [2 2; 2 -2; -2 2; -2 -2];
        candidates = [row col] + steps;
        mids = [row col] + steps / 2;
        valid = candidates(:, 1) >= 1 & candidates(:, 1) <= 10 & ...
            candidates(:, 2) >= 1 & candidates(:, 2) <= 9;
        midOpen = false(size(valid));
        midOpen(valid) = board(sub2ind(size(board), mids(valid, 1), mids(valid, 2))) == 0;
        valid = valid & midOpen;
        if isRed
            valid = valid & candidates(:, 1) >= 6;
        else
            valid = valid & candidates(:, 1) <= 5;
        end
        targets = candidates(valid, :);
    case 4
        steps = [2 1; 2 -1; -2 1; -2 -1; 1 2; 1 -2; -1 2; -1 -2];
        candidates = [row col] + steps;
        legs = [row + sign(steps(:, 1)) .* (abs(steps(:, 1)) == 2), ...
                col + sign(steps(:, 2)) .* (abs(steps(:, 2)) == 2)];
        valid = candidates(:, 1) >= 1 & candidates(:, 1) <= 10 & ...
            candidates(:, 2) >= 1 & candidates(:, 2) <= 9;
        legOpen = false(size(valid));
        legOpen(valid) = board(sub2ind(size(board), legs(valid, 1), legs(valid, 2))) == 0;
        valid = valid & legOpen;
        targets = candidates(valid, :);
    case 5
        targets = sliding_targets(board, row, col, false);
    case 6
        targets = sliding_targets(board, row, col, true);
    case 7
        if isRed
            steps = [-1 0];
            if row <= 5, steps = [steps; 0 1; 0 -1]; end
        else
            steps = [1 0];
            if row >= 6, steps = [steps; 0 1; 0 -1]; end
        end
        candidates = [row col] + steps;
        valid = candidates(:, 1) >= 1 & candidates(:, 1) <= 10 & ...
            candidates(:, 2) >= 1 & candidates(:, 2) <= 9;
        targets = candidates(valid, :);
end
if isempty(targets)
    return;
end
occupants = board(sub2ind(size(board), targets(:, 1), targets(:, 2)));
if isRed
    targets = targets(occupants == 0 | occupants >= 8, :);
else
    targets = targets(occupants == 0 | occupants <= 7, :);
end
end

function targets = sliding_targets(board, row, col, isCannon)
directions = [1 0; -1 0; 0 1; 0 -1];
targets = zeros(0, 2);
for direction = directions'
    r = row;
    c = col;
    screenSeen = false;
    while true
        r = r + direction(1);
        c = c + direction(2);
        if r < 1 || r > 10 || c < 1 || c > 9
            break;
        end
        occupied = board(r, c) ~= 0;
        if ~isCannon
            targets = [targets; r c]; %#ok<AGROW>
            if occupied, break; end
        elseif ~screenSeen
            if occupied
                screenSeen = true;
            else
                targets = [targets; r c]; %#ok<AGROW>
            end
        elseif occupied
            targets = [targets; r c]; %#ok<AGROW>
            break;
        end
    end
end
end
