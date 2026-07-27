function next = next_state(state, move)
%NEXT_STATE Apply a legal move and update turn, repetition, and ply data.
moves = alphazero.legal_moves(state);
move = reshape(move, 1, []);
if numel(move) ~= 4 || ~any(ismember(moves, move, "rows"))
    error("alphazero:IllegalMove", "Move must be legal in the supplied state.");
end

board = xiangqi.apply_move(state.board, move);
player = xiangqi.opponent(state.player);
positionCounts = duplicate_counts(state.positionCounts);
key = char(xiangqi.position_key(board, player));
if isKey(positionCounts, key)
    positionCounts(key) = positionCounts(key) + 1;
else
    positionCounts(key) = 1;
end
next = struct("board", board, "player", player, "positionCounts", positionCounts, ...
    "ply", state.ply + 1, "maxPlies", state.maxPlies);
end

function target = duplicate_counts(source)
target = containers.Map("KeyType", "char", "ValueType", "double");
keys = source.keys;
for index = 1:numel(keys)
    target(keys{index}) = source(keys{index});
end
end
