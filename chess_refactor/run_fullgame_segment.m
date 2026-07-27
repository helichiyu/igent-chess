function history = run_fullgame_segment(iterations)
%RUN_FULLGAME_SEGMENT Continue a bounded number of full-game training rounds.
validateattributes(iterations, {'numeric'}, {'scalar', 'integer', 'positive'});
history = train_fullgame_alphazero(struct("iterations", iterations));
end
