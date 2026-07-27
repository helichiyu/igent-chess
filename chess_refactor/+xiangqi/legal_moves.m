function moves = legal_moves(board, player)
%LEGAL_MOVES Return every move that does not leave PLAYER's general in check.
candidateMoves = xiangqi.pseudo_moves(board, player);
keep = false(size(candidateMoves, 1), 1);
for index = 1:size(candidateMoves, 1)
    nextBoard = xiangqi.apply_move(board, candidateMoves(index, :));
    keep(index) = ~xiangqi.is_in_check(nextBoard, player);
end
moves = candidateMoves(keep, :);
end
