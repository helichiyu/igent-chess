classdef TestAlphaZeroState < matlab.unittest.TestCase
    methods (Test)
        function initialPositionsArePlayable(testCase)
            positions = alphazero.initial_positions();
            testCase.verifyEqual(numel(positions), 4);
            for index = 1:numel(positions)
                state = alphazero.new_state(positions(index).board, positions(index).player);
                outcome = alphazero.game_state(state);
                testCase.verifyFalse(outcome.isOver, positions(index).name);
                testCase.verifyNotEmpty(alphazero.legal_moves(state), positions(index).name);
            end
        end

        function transitionMatchesRuleEngine(testCase)
            position = alphazero.initial_positions();
            state = alphazero.new_state(position(1).board, position(1).player, 10);
            move = alphazero.legal_moves(state);
            move = move(1, :);
            expectedBoard = xiangqi.apply_move(state.board, move);
            next = alphazero.next_state(state, move);
            testCase.verifyEqual(next.board, expectedBoard);
            testCase.verifyEqual(next.player, xiangqi.opponent(state.player));
            testCase.verifyEqual(next.ply, 1);
            key = char(xiangqi.position_key(next.board, next.player));
            testCase.verifyEqual(next.positionCounts(key), 1);
        end

        function terminalOutcomeMatchesRuleEngine(testCase)
            board = xiangqi.new_board();
            board(board == 8) = 0;
            state = alphazero.new_state(board, 1, 10);
            expected = xiangqi.game_state(board, 1, state.positionCounts);
            actual = alphazero.game_state(state);
            testCase.verifyEqual(actual.isOver, expected.isOver);
            testCase.verifyEqual(actual.result, expected.result);
            testCase.verifyEqual(actual.winner, expected.winner);
        end

        function maximumPliesEndsInDraw(testCase)
            position = alphazero.initial_positions();
            state = alphazero.new_state(position(4).board, position(4).player, 1);
            move = alphazero.legal_moves(state);
            next = alphazero.next_state(state, move(1, :));
            outcome = alphazero.game_state(next);
            testCase.verifyTrue(outcome.isOver);
            testCase.verifyEqual(outcome.result, "max_plies");
            testCase.verifyEqual(outcome.winner, 0);
        end
    end
end
