function action = encode_move(move, player)
%ENCODE_MOVE Map a move to its current-player-perspective action index.
validateattributes(move, {'numeric'}, {'vector', 'numel', 4, 'integer'});
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error("alphazero:InvalidPlayer", "Player must be 1 (red) or -1 (black).");
end
move = reshape(move, 1, []);
if any(move([1 3]) < 1 | move([1 3]) > 10) || ...
        any(move([2 4]) < 1 | move([2 4]) > 9)
    error("alphazero:InvalidMove", "Move coordinates are outside the board.");
end
if player == -1
    move = [11 - move(1), 10 - move(2), 11 - move(3), 10 - move(4)];
end
source = square_index(move(1), move(2));
target = square_index(move(3), move(4));
action = (source - 1) * 90 + target;
end

function index = square_index(row, col)
index = (row - 1) * 9 + col;
end
