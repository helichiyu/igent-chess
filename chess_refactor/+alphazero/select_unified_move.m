function [move, metadata] = select_unified_move(net, board, player, positionCounts, ply, settings)
%SELECT_UNIFIED_MOVE Choose one legal move with the shared AlphaZero model.
if nargin < 6 || isempty(settings)
    settings = alphazero.fullgame_config();
end
if nargin < 5 || isempty(ply)
    ply = 0;
end
if nargin < 4 || isempty(positionCounts)
    state = alphazero.new_state(board, player, settings.maxPlies);
else
    state = struct("board", board, "player", player, ...
        "positionCounts", positionCounts, "ply", ply, "maxPlies", settings.maxPlies);
end
[move, ~] = alphazero.mcts_search(net, state, settings);
metadata = struct("networkVersion", settings.networkVersion, ...
    "mctsSimulations", settings.mctsSimulations);
end
