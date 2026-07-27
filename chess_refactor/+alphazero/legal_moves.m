function moves = legal_moves(state)
%LEGAL_MOVES Return legal moves from an AlphaZero search state.
validate_state(state);
moves = xiangqi.legal_moves(state.board, state.player);
end

function validate_state(state)
required = ["board" "player" "positionCounts" "ply" "maxPlies"];
if ~isstruct(state) || ~all(isfield(state, required))
    error("alphazero:InvalidState", "State does not contain the required fields.");
end
end
