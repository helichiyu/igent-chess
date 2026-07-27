function inCheck = is_in_check(board, player)
%IS_IN_CHECK True when PLAYER's general is attacked in BOARD.
validateattributes(board, {'numeric'}, {'size', [10 9]});
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error('xiangqi:InvalidPlayer', 'Player must be 1 (red) or -1 (black).');
end
king = 1;
if player == -1, king = 8; end
[kingRow, kingCol] = find(board == king, 1);
if isempty(kingRow)
    inCheck = true;
    return;
end
inCheck = is_square_attacked(board, kingRow, kingCol, xiangqi.opponent(player));
end

function attacked = is_square_attacked(board, targetRow, targetCol, attacker)
attacked = false;
if attacker == 1
    locations = find(board >= 1 & board <= 7);
else
    locations = find(board >= 8 & board <= 14);
end
for index = reshape(locations, 1, [])
    [row, col] = ind2sub(size(board), index);
    piece = board(row, col);
    type = mod(piece - 1, 7) + 1;
    if type == 1
        % Adjacent general attacks plus the flying-general attack.
        if abs(row - targetRow) + abs(col - targetCol) == 1
            attacked = true;
            return;
        end
        if col == targetCol && all(board(min(row, targetRow)+1:max(row, targetRow)-1, col) == 0)
            attacked = true;
            return;
        end
        continue;
    end
    targets = xiangqi.pseudo_moves_for_piece(board, row, col);
    if any(targets(:, 1) == targetRow & targets(:, 2) == targetCol)
        attacked = true;
        return;
    end
end
end
