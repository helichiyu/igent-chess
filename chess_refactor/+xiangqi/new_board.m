function board = new_board()
%NEW_BOARD Return the standard Chinese-chess opening position.
board = zeros(10, 9);
board(10, :) = [5 4 3 2 1 2 3 4 5];
board(8, [2 8]) = 6;
board(7, [1 3 5 7 9]) = 7;
board(1, :) = [12 11 10 9 8 9 10 11 12];
board(3, [2 8]) = 13;
board(4, [1 3 5 7 9]) = 14;
end
