function history = run_fullgame_smoke()
%RUN_FULLGAME_SMOKE Run the smallest GPU-capable full-game verification segment.
settings = alphazero.fullgame_preset("smoke");
history = train_fullgame_alphazero(settings);
end
