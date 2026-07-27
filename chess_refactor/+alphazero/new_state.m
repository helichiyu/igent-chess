function state = new_state(board, player, maxPlies)
%NEW_STATE Create a search state backed by the xiangqi rule engine.
if nargin < 3 || isempty(maxPlies)
    settings = alphazero.config();
    maxPlies = settings.maxPlies;
end
validateattributes(board, {'numeric'}, {'size', [10 9]});
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error("alphazero:InvalidPlayer", "Player must be 1 (red) or -1 (black).");
end
validateattributes(maxPlies, {'numeric'}, {'scalar', 'integer', 'positive'});

positionCounts = containers.Map("KeyType", "char", "ValueType", "double");
positionCounts(char(xiangqi.position_key(board, player))) = 1;
state = struct("board", board, "player", player, "positionCounts", positionCounts, ...
    "ply", 0, "maxPlies", maxPlies);
end
