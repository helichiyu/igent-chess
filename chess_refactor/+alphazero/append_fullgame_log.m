function append_fullgame_log(logDirectory, record)
%APPEND_FULLGAME_LOG Add one compact, append-only iteration metrics row.
if ~isfolder(logDirectory)
    mkdir(logDirectory);
end
path = fullfile(logDirectory, "iteration_metrics.csv");
newFile = ~isfile(path);
file = fopen(path, "a");
if file < 0
    error("alphazero:LogWriteFailed", "Could not open %s for writing.", path);
end
cleanup = onCleanup(@()fclose(file)); %#ok<NASGU>
if newFile
    header = ["iteration,replay_samples,loss,policy_loss,value_loss," ...
        "elapsed_seconds,evaluation_score,promoted,self_play_games,average_plies," ...
        "max_plies_draws,repetition_draws,network_version,mcts_simulations\n"];
    fprintf(file, "%s", char(header));
end
fprintf(file, "%d,%d,%.8g,%.8g,%.8g,%.8g,%.8g,%d,%d,%.8g,%d,%d,%s,%d\n", ...
    record.iteration, record.samples, record.loss, record.policyLoss, ...
    record.valueLoss, record.elapsedSeconds, record.evaluation.score, ...
    record.evaluation.promoted, record.selfPlayGames, record.averagePlies, ...
    record.maxPliesDraws, record.repetitionDraws, string(record.networkVersion), ...
    record.mctsSimulations);
end
