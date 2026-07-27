function key = position_key(board, player)
%POSITION_KEY Create a stable position identifier for repetition detection.
key = string(sprintf("%d,", board(:))) + "|" + string(player);
end
