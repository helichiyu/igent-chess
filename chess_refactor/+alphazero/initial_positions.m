function positions = initial_positions()
%INITIAL_POSITIONS Return fixed legal general-general-rook validation starts.
% Each row is independently constructed to keep the experiment reproducible.
positions = repmat(struct("board", zeros(10, 9), "player", 1, "name", ""), 4, 1);

positions(1).board = make_board([10 5], [1 5], [4 5]);
positions(1).player = -1;
positions(1).name = "central_rook_check";

positions(2).board = make_board([10 6], [1 4], [5 4]);
positions(2).player = -1;
positions(2).name = "left_file_check";

positions(3).board = make_board([10 4], [1 6], [5 6]);
positions(3).player = -1;
positions(3).name = "right_file_check";

positions(4).board = make_board([9 5], [2 4], [6 5]);
positions(4).player = 1;
positions(4).name = "quiet_rook_position";

for index = 1:numel(positions)
    outcome = xiangqi.game_state(positions(index).board, positions(index).player);
    if outcome.isOver
        error("alphazero:InvalidInitialPosition", ...
            "Initial position %s is already terminal.", positions(index).name);
    end
end
end

function board = make_board(redGeneral, blackGeneral, redRook)
board = zeros(10, 9);
board(redGeneral(1), redGeneral(2)) = 1;
board(blackGeneral(1), blackGeneral(2)) = 8;
board(redRook(1), redRook(2)) = 5;
end
