function state = game_state(board, player, positionCounts)
%GAME_STATE Describe whether play continues, is checkmate, stalemate, or draw.
% POSITIONCOUNTS is optional and maps canonical board positions to occurrences.
validateattributes(board, {"numeric"}, {"size", [10 9]});
validateattributes(player, {"numeric"}, {"scalar", "member", [-1 1]});
state = struct("isOver", false, "result", "ongoing", "winner", 0, ...
    "inCheck", false, "legalMoves", zeros(0, 4));
if ~any(board(:) == 1)
    state.isOver = true; state.result = "captured_general"; state.winner = -1; return;
end
if ~any(board(:) == 8)
    state.isOver = true; state.result = "captured_general"; state.winner = 1; return;
end
if nargin >= 3 && ~isempty(positionCounts)
    key = xiangqi.position_key(board, player);
    if isKey(positionCounts, key) && positionCounts(key) >= 3
        state.isOver = true; state.result = "threefold_repetition"; return;
    end
end
state.inCheck = xiangqi.is_in_check(board, player);
state.legalMoves = xiangqi.legal_moves(board, player);
if isempty(state.legalMoves)
    state.isOver = true;
    if state.inCheck
        state.result = "checkmate";
        state.winner = xiangqi.opponent(player);
    else
        state.result = "stalemate";
    end
end
end
