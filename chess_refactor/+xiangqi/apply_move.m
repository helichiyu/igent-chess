function nextBoard = apply_move(board, move)
%APPLY_MOVE Apply one [sourceRow sourceCol targetRow targetCol] move.
validateattributes(board, {'numeric'}, {'size', [10 9]});
validateattributes(move, {'numeric'}, {'vector', 'numel', 4, 'integer'});
move = reshape(move, 1, []);
if any(move([1 3]) < 1 | move([1 3]) > 10) || ...
        any(move([2 4]) < 1 | move([2 4]) > 9)
    error("xiangqi:InvalidMove", "Move coordinates are outside the board.");
end
if board(move(1), move(2)) == 0
    error("xiangqi:InvalidMove", "A move must start on an occupied square.");
end
nextBoard = board;
nextBoard(move(3), move(4)) = nextBoard(move(1), move(2));
nextBoard(move(1), move(2)) = 0;
end
