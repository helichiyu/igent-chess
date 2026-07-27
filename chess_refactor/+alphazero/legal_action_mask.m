function mask = legal_action_mask(state)
%LEGAL_ACTION_MASK Return a 8100-element mask generated from legal moves.
moves = alphazero.legal_moves(state);
mask = false(8100, 1);
for index = 1:size(moves, 1)
    mask(alphazero.encode_move(moves(index, :), state.player)) = true;
end
end
