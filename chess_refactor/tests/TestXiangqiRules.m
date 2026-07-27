classdef TestXiangqiRules < matlab.unittest.TestCase
    methods (Test)
        function openingHasExpectedPieceCount(testCase)
            board = xiangqi.new_board();
            testCase.verifyEqual(nnz(board >= 1 & board <= 7), 16);
            testCase.verifyEqual(nnz(board >= 8 & board <= 14), 16);
        end

        function openingHasFortyFourLegalMoves(testCase)
            moves = xiangqi.legal_moves(xiangqi.new_board(), 1);
            testCase.verifyEqual(size(moves, 1), 44);
        end

        function horseLegBlocksMove(testCase)
            board = zeros(10, 9);
            board(10, 5) = 1;
            board(1, 5) = 8;
            board(6, 5) = 4;
            board(7, 5) = 7;
            targets = xiangqi.pseudo_moves_for_piece(board, 6, 5);
            testCase.verifyFalse(any(ismember(targets, [8 4], "rows")));
            testCase.verifyFalse(any(ismember(targets, [8 6], "rows")));
        end

        function elephantCannotCrossRiver(testCase)
            board = zeros(10, 9);
            board(10, 5) = 1;
            board(1, 5) = 8;
            board(6, 3) = 3;
            targets = xiangqi.pseudo_moves_for_piece(board, 6, 3);
            testCase.verifyFalse(any(targets(:, 1) < 6));
        end

        function cannonNeedsExactlyOneScreenToCapture(testCase)
            board = zeros(10, 9);
            board(10, 5) = 1;
            board(1, 5) = 8;
            board(5, 5) = 6;
            board(5, 6) = 7;
            board(5, 8) = 12;
            targets = xiangqi.pseudo_moves_for_piece(board, 5, 5);
            testCase.verifyTrue(any(ismember(targets, [5 8], "rows")));
            board(5, 7) = 7;
            targets = xiangqi.pseudo_moves_for_piece(board, 5, 5);
            testCase.verifyFalse(any(ismember(targets, [5 8], "rows")));
        end

        function pinnedPieceCannotExposeGeneral(testCase)
            board = zeros(10, 9);
            board(10, 5) = 1;
            board(1, 5) = 8;
            board(7, 5) = 5;
            board(4, 5) = 12;
            legal = xiangqi.legal_moves(board, 1);
            testCase.verifyFalse(any(legal(:, 1) == 7 & legal(:, 2) == 5 & legal(:, 4) ~= 5));
        end

        function missingGeneralEndsGame(testCase)
            board = xiangqi.new_board();
            board(board == 8) = 0;
            state = xiangqi.game_state(board, 1);
            testCase.verifyTrue(state.isOver);
            testCase.verifyEqual(state.winner, 1);
        end
    end
end
