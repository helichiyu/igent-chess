function encoded = encode_state(state)
%ENCODE_STATE Encode a state as fourteen current-player-perspective planes.
if ~isstruct(state) || ~isfield(state, "board") || ~isfield(state, "player")
    error("alphazero:InvalidState", "State must contain board and player fields.");
end
board = canonical_board(state.board, state.player);
encoded = zeros(10, 9, 14, "single");
for piece = 1:14
    encoded(:, :, piece) = single(board == piece);
end
end

function board = canonical_board(board, player)
if player == 1
    return;
end
board = rot90(board, 2);
black = board >= 8 & board <= 14;
red = board >= 1 & board <= 7;
board(black) = board(black) - 7;
board(red) = board(red) + 7;
end
