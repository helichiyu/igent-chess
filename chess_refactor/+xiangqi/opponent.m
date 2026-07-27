function other = opponent(player)
%OPPONENT Convert a player indicator between red (1) and black (-1).
validateattributes(player, {"numeric"}, {"scalar", "member", [-1 1]});
other = -player;
end
