classdef TestAlphaZeroMCTS < matlab.unittest.TestCase
    methods (Test)
        function searchReturnsLegalMoveAndNormalizedVisits(testCase)
            net = alphazero.create_network();
            positions = alphazero.initial_positions();
            state = alphazero.new_state(positions(4).board, positions(4).player, 10);
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 4;
            [move, policy, root] = alphazero.mcts_search(net, state, settings);
            moves = alphazero.legal_moves(state);
            testCase.verifyTrue(any(ismember(moves, move, "rows")));
            testCase.verifyEqual(sum(policy), single(1), AbsTol=1e-6);
            testCase.verifyEqual(sum(root.VisitCounts), settings.mctsSimulations);
            testCase.verifyEqual(nnz(policy), nnz(root.VisitCounts));
        end

        function terminalStateReturnsNoMove(testCase)
            board = xiangqi.new_board();
            board(board == 8) = 0;
            state = alphazero.new_state(board, 1);
            settings = alphazero.config();
            settings.useGPU = false;
            [move, policy, root] = alphazero.mcts_search( ...
                alphazero.create_network(), state, settings);
            testCase.verifyEmpty(move);
            testCase.verifyEqual(nnz(policy), 0);
            testCase.verifyFalse(root.Expanded);
        end
    end
end
