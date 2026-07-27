function other = opponent(player)
%OPPONENT Convert a player indicator between red (1) and black (-1).
if ~isnumeric(player) || ~isscalar(player) || ~ismember(player, [-1 1])
    error('xiangqi:InvalidPlayer', 'Player must be 1 (red) or -1 (black).');
end
other = -player;
end
