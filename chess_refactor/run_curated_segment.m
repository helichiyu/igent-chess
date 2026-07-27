function history = run_curated_segment(iterations)
%RUN_CURATED_SEGMENT Continue a bounded number of curated training rounds.
validateattributes(iterations, {'numeric'}, {'scalar', 'integer', 'positive'});
history = train_endgame_alphazero(struct("iterations", iterations));
end
