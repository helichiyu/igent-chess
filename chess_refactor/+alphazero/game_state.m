function outcome = game_state(state)
%GAME_STATE Return the rule outcome, with maximum plies treated as a draw.
validate_state(state);
outcome = xiangqi.game_state(state.board, state.player, state.positionCounts);
if ~outcome.isOver && state.ply >= state.maxPlies
    outcome.isOver = true;
    outcome.result = "max_plies";
    outcome.winner = 0;
end
end

function validate_state(state)
required = ["board" "player" "positionCounts" "ply" "maxPlies"];
if ~isstruct(state) || ~all(isfield(state, required))
    error("alphazero:InvalidState", "State does not contain the required fields.");
end
end
