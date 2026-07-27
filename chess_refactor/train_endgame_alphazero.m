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
if isfile(bestPath)
    [bestNet, ~] = alphazero.load_model(bestPath);
else
    bestNet = alphazero.create_network();
    alphazero.save_model(bestNet, bestPath, checkpoint_metadata(settings, positions, 0, struct()));
end
buffer = alphazero.load_replay_chunks(replayDirectory, settings.replayCapacity);
history = repmat(struct("iteration", 0, "samples", 0, "loss", NaN, ...
    "evaluation", struct(), "selfPlay", struct()), settings.iterations, 1);

for iteration = 1:settings.iterations
    generated = struct("state", {}, "policy", {}, "legalMask", {}, ...
        "player", {}, "value", {}, "scenarioId", {});
    selfPlayMetrics = repmat(struct("scenarioId", "", "plies", 0, ...
        "result", "", "winner", 0, "repetitionDraw", false), ...
        settings.selfPlayGamesPerIteration, 1);
    for gameIndex = 1:settings.selfPlayGamesPerIteration
        position = positions(mod(gameIndex - 1, numel(positions)) + 1);
        [samples, ~, selfPlayMetrics(gameIndex)] = alphazero.self_play(bestNet, position, settings);
        generated = [generated samples]; %#ok<AGROW>
    end
    buffer.add(generated);
    alphazero.save_replay_chunk(generated, replayDirectory, iteration);

    candidateNet = bestNet;
    optimizer = [];
    metrics = struct("loss", NaN);
    for step = 1:settings.trainingStepsPerIteration
        [states, policies, values, masks] = buffer.sample(settings.batchSize);
        [candidateNet, optimizer, metrics] = alphazero.train_step( ...
            candidateNet, states, policies, values, masks, optimizer, settings);
    end
    evaluation = alphazero.evaluate_models(candidateNet, bestNet, positions, settings);
    if evaluation.promoted
        bestNet = candidateNet;
        alphazero.save_model(bestNet, bestPath, ...
            checkpoint_metadata(settings, positions, iteration, evaluation));
    end
    history(iteration) = struct("iteration", iteration, "samples", buffer.count(), ...
        "loss", metrics.loss, "evaluation", evaluation, ...
        "selfPlay", summarize_self_play(selfPlayMetrics, positions));
end
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
