function moves = pseudo_moves(board, player)
%PSEUDO_MOVES Return moves obeying piece movement rules before self-check filtering.
validateattributes(board, {"numeric"}, {"size", [10 9]});
validateattributes(player, {"numeric"}, {"scalar", "member", [-1 1]});
if player == 1
    locations = find(board >= 1 & board <= 7);
else
    locations = find(board >= 8 & board <= 14);
end
moves = zeros(0, 4);
for index = reshape(locations, 1, [])
    [row, col] = ind2sub(size(board), index);
    targets = xiangqi.pseudo_moves_for_piece(board, row, col);
    moves = [moves; repmat([row col], size(targets, 1), 1), targets]; %#ok<AGROW>
end
end
