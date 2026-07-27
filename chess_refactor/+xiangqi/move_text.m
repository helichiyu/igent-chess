function text = move_text(board, move)
%MOVE_TEXT Format a move compactly for the GUI status display.
piece = xiangqi.piece_name(board(move(1), move(2)));
text = sprintf("%s (%d,%d) -> (%d,%d)", piece, move(1), move(2), move(3), move(4));
end
