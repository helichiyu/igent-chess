classdef TestAlphaZeroRepresentation < matlab.unittest.TestCase
    methods (Test)
        function legalMovesRoundTripForBothPlayers(testCase)
            positions = alphazero.initial_positions();
            for index = 1:numel(positions)
                state = alphazero.new_state(positions(index).board, positions(index).player);
                moves = alphazero.legal_moves(state);
                for moveIndex = 1:size(moves, 1)
                    action = alphazero.encode_move(moves(moveIndex, :), state.player);
                    testCase.verifyEqual(alphazero.decode_move(action, state.player), moves(moveIndex, :));
                end
            end
        end

        function legalMaskContainsOnlyRuleEngineMoves(testCase)
            positions = alphazero.initial_positions();
            for index = 1:numel(positions)
                state = alphazero.new_state(positions(index).board, positions(index).player);
                mask = alphazero.legal_action_mask(state);
                moves = alphazero.legal_moves(state);
                actions = zeros(size(moves, 1), 1);
                for moveIndex = 1:size(moves, 1)
                    actions(moveIndex) = alphazero.encode_move(moves(moveIndex, :), state.player);
                end
                testCase.verifyEqual(nnz(mask), size(moves, 1));
                testCase.verifyTrue(all(mask(actions)));
                decoded = find(mask);
                for action = reshape(decoded, 1, [])
                    move = alphazero.decode_move(action, state.player);
                    testCase.verifyTrue(any(ismember(moves, move, "rows")));
                end
            end
        end

        function blackPerspectiveBecomesRedPerspective(testCase)
            board = zeros(10, 9);
            board(1, 4) = 8;
            board(2, 4) = 12;
            board(10, 6) = 1;
            state = alphazero.new_state(board, -1);
            encoded = alphazero.encode_state(state);
            testCase.verifyEqual(encoded(10, 6, 1), single(1));
            testCase.verifyEqual(encoded(9, 6, 5), single(1));
            testCase.verifyEqual(encoded(1, 4, 8), single(1));
            testCase.verifyEqual(nnz(encoded), 3);
        end
    end
end
