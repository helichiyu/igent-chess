function move = decode_move(action, player)
%DECODE_MOVE Convert a current-player-perspective action index to a move.
validateattributes(action, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 8100});
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error("alphazero:InvalidPlayer", "Player must be 1 (red) or -1 (black).");
end
source = floor((action - 1) / 90) + 1;
target = mod(action - 1, 90) + 1;
[sourceRow, sourceCol] = square_coordinates(source);
[targetRow, targetCol] = square_coordinates(target);
move = [sourceRow sourceCol targetRow targetCol];
if player == -1
    move = [11 - move(1), 10 - move(2), 11 - move(3), 10 - move(4)];
end
end

function [row, col] = square_coordinates(index)
row = floor((index - 1) / 9) + 1;
col = mod(index - 1, 9) + 1;
end
