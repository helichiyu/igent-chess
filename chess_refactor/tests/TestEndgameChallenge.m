classdef TestEndgameChallenge < matlab.unittest.TestCase
    methods (Test)
        function newChallengeStateMatchesScenario(testCase)
            scenarios = alphazero.curated_scenarios();
            state = alphazero.new_challenge_state(scenarios(1));
            testCase.verifyEqual(state.board, scenarios(1).board);
            testCase.verifyEqual(state.player, scenarios(1).player);
            testCase.verifyEqual(state.maxPlies, scenarios(1).maxPlies);
            testCase.verifyEqual(state.humanPlayer, 1);
            testCase.verifyFalse(state.isOver);
        end

        function challengeGoalUsesFinalOutcome(testCase)
            scenarios = alphazero.curated_scenarios();
            redWin = struct("winner", 1);
            draw = struct("winner", 0);
            testCase.verifyTrue(alphazero.challenge_succeeded(scenarios(1), redWin));
            testCase.verifyTrue(alphazero.challenge_succeeded(scenarios(5), draw));
        end

        function transitionRetainsChallengeContext(testCase)
            scenarios = alphazero.curated_scenarios();
            state = alphazero.new_challenge_state(scenarios(1));
            moves = alphazero.legal_moves(state);
            next = alphazero.next_challenge_state(state, moves(1, :));
            testCase.verifyEqual(next.scenario.id, scenarios(1).id);
            testCase.verifyEqual(next.humanPlayer, state.humanPlayer);
            testCase.verifyEqual(next.lastMove, moves(1, :));
            testCase.verifyFalse(next.isOver);
        end
    end
end
