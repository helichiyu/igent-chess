function state = new_challenge_state(scenario)
%NEW_CHALLENGE_STATE Create GUI state for one curated challenge scenario.
state = alphazero.new_state(scenario.board, scenario.player, scenario.maxPlies);
state.scenario = scenario;
state.humanPlayer = scenario.challengePlayer;
state.isOver = false;
state.lastMove = zeros(0, 4);
end
