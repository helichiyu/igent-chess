function next = next_challenge_state(state, move)
%NEXT_CHALLENGE_STATE Apply a move while retaining GUI challenge context.
next = alphazero.next_state(state, move);
next.scenario = state.scenario;
next.humanPlayer = state.humanPlayer;
next.isOver = false;
next.lastMove = move;
end
