function moves = pseudo_moves(board, player)
%PSEUDO_MOVES Return moves obeying piece movement rules before self-check filtering.
validateattributes(board, {'numeric'}, {'size', [10 9]});
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error('xiangqi:InvalidPlayer', 'Player must be 1 (red) or -1 (black).');
end
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
