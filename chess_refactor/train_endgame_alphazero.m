function history = train_endgame_alphazero(overrides)
%TRAIN_ENDGAME_ALPHAZERO Run the bounded endgame AlphaZero validation loop.
if nargin < 1
    overrides = struct();
end
settings = apply_overrides(alphazero.config(), overrides);
rng(settings.randomSeed);
alphazero.prepare_execution(settings);

positions = alphazero.curated_scenarios();
projectRoot = fileparts(mfilename("fullpath"));
modelDirectory = resolve_output_directory(projectRoot, settings.modelDirectory);
replayDirectory = resolve_output_directory(projectRoot, settings.replayDirectory);
bestPath = fullfile(modelDirectory, "best_model.mat");
progressPath = fullfile(modelDirectory, "training_progress.mat");
if isfile(bestPath)
    [bestNet, existingMetadata] = alphazero.load_model(bestPath);
    if isfield(existingMetadata, "networkVersion") && ...
            string(existingMetadata.networkVersion) == alphazero.fullgame_network_version()
        error("alphazero:RetiredEndgameTraining", ...
            "Use train_fullgame_alphazero; curated positions will return as a full-game mixture.");
    end
else
    bestNet = alphazero.create_network();
    alphazero.save_model(bestNet, bestPath, checkpoint_metadata(settings, positions, 0, struct()));
end
buffer = alphazero.load_replay_chunks(replayDirectory, settings.replayCapacity);
completedIterations = load_completed_iterations(progressPath);
history = repmat(struct("iteration", 0, "samples", 0, "loss", NaN, ...
    "evaluation", struct(), "selfPlay", struct()), settings.iterations, 1);
fprintf("Training segment: %d iteration(s), resuming after iteration %d.\n", ...
    settings.iterations, completedIterations);

for localIteration = 1:settings.iterations
    iteration = completedIterations + localIteration;
    iterationTimer = tic;
    fprintf("\nIteration %d started (%d of %d in this segment).\n", ...
        iteration, localIteration, settings.iterations);
    generated = struct("state", {}, "policy", {}, "legalMask", {}, ...
        "player", {}, "value", {}, "scenarioId", {});
    selfPlayMetrics = repmat(struct("scenarioId", "", "plies", 0, ...
        "result", "", "winner", 0, "repetitionDraw", false, ...
        "mctsSimulations", 0, "networkVersion", ""), ...
        settings.selfPlayGamesPerIteration, 1);
    for gameIndex = 1:settings.selfPlayGamesPerIteration
        position = positions(mod(gameIndex - 1, numel(positions)) + 1);
        [samples, ~, selfPlayMetrics(gameIndex)] = alphazero.self_play(bestNet, position, settings);
        generated = [generated samples]; %#ok<AGROW>
        fprintf("  Self-play %d/%d: %s | %d plies | %s\n", ...
            gameIndex, settings.selfPlayGamesPerIteration, position.id, ...
            selfPlayMetrics(gameIndex).plies, selfPlayMetrics(gameIndex).result);
    end
    buffer.add(generated);
    alphazero.save_replay_chunk(generated, replayDirectory, iteration);
    fprintf("  Replay buffer: %d samples.\n", buffer.count());

    candidateNet = bestNet;
    optimizer = [];
    metrics = struct("loss", NaN);
    for step = 1:settings.trainingStepsPerIteration
        [states, policies, values, masks] = buffer.sample(settings.batchSize);
        [candidateNet, optimizer, metrics] = alphazero.train_step( ...
            candidateNet, states, policies, values, masks, optimizer, settings);
    end
    fprintf("  Training: %d step(s) | loss %.4f | policy %.4f | value %.4f\n", ...
        settings.trainingStepsPerIteration, metrics.loss, metrics.policyLoss, metrics.valueLoss);
    evaluation = alphazero.evaluate_models(candidateNet, bestNet, positions, settings);
    print_evaluation(evaluation);
    if evaluation.promoted
        bestNet = candidateNet;
        alphazero.save_model(bestNet, bestPath, ...
            checkpoint_metadata(settings, positions, iteration, evaluation));
        fprintf("  Checkpoint promoted.\n");
    else
        fprintf("  Checkpoint retained.\n");
    end
    history(localIteration) = struct("iteration", iteration, "samples", buffer.count(), ...
        "loss", metrics.loss, "evaluation", evaluation, ...
        "selfPlay", summarize_self_play(selfPlayMetrics, positions));
    save_progress(progressPath, iteration, positions);
    fprintf("Iteration %d completed in %.1f seconds.\n", iteration, toc(iterationTimer));
end
end

function print_evaluation(evaluation)
fprintf("  Evaluation: score %.3f | promoted %s\n", ...
    evaluation.score, string(evaluation.promoted));
for index = 1:numel(evaluation.perScenario)
    item = evaluation.perScenario(index);
    fprintf("    %s: score %.3f | W-D-L %d-%d-%d | %.1f plies | repetitions %d\n", ...
        item.id, item.candidateScore, item.wins, item.draws, item.losses, ...
        item.averagePlies, item.repetitionDraws);
end
end

function completedIterations = load_completed_iterations(progressPath)
completedIterations = 0;
if ~isfile(progressPath)
    return;
end
data = load(progressPath, "completedIterations");
completedIterations = data.completedIterations;
end

function save_progress(progressPath, completedIterations, scenarios)
scenarioDataVersion = scenarios(1).source.dataVersion;
scenarioIds = string({scenarios.id});
save(progressPath, "completedIterations", "scenarioDataVersion", "scenarioIds");
end

function summary = summarize_self_play(metrics, scenarios)
summary = repmat(struct("id", "", "games", 0, "averagePlies", 0, ...
    "repetitionDraws", 0), numel(scenarios), 1);
for index = 1:numel(scenarios)
    matches = string({metrics.scenarioId}) == scenarios(index).id;
    selected = metrics(matches);
    if isempty(selected)
        continue;
    end
    summary(index) = struct("id", scenarios(index).id, "games", numel(selected), ...
        "averagePlies", mean([selected.plies]), ...
        "repetitionDraws", sum([selected.repetitionDraw]));
end
end

function metadata = checkpoint_metadata(settings, scenarios, iteration, evaluation)
metadata = struct("settings", settings, "iteration", iteration, ...
    "evaluation", evaluation, "scenarioDataVersion", scenarios(1).source.dataVersion, ...
    "scenarioIds", string({scenarios.id}));
end

function directory = resolve_output_directory(projectRoot, directory)
directory = string(directory);
if isempty(regexp(directory, "^[A-Za-z]:[\\\\/]", "once")) && ...
        ~startsWith(directory, "\\\\")
    directory = fullfile(projectRoot, directory);
end
end

function settings = apply_overrides(settings, overrides)
names = fieldnames(overrides);
for index = 1:numel(names)
    if ~isfield(settings, names{index})
        error("alphazero:UnknownSetting", "Unknown setting: %s.", names{index});
    end
    settings.(names{index}) = overrides.(names{index});
end
end
