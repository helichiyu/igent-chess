function history = train_endgame_alphazero(overrides)
%TRAIN_ENDGAME_ALPHAZERO Run the bounded endgame AlphaZero validation loop.
if nargin < 1
    overrides = struct();
end
settings = apply_overrides(alphazero.config(), overrides);
rng(settings.randomSeed);
if settings.useGPU && ~canUseGPU
    error("alphazero:GPUUnavailable", "GPU execution was requested but no supported GPU is available.");
end

positions = alphazero.initial_positions();
projectRoot = fileparts(mfilename("fullpath"));
modelDirectory = resolve_output_directory(projectRoot, settings.modelDirectory);
replayDirectory = resolve_output_directory(projectRoot, settings.replayDirectory);
bestPath = fullfile(modelDirectory, "best_model.mat");
if isfile(bestPath)
    [bestNet, ~] = alphazero.load_model(bestPath);
else
    bestNet = alphazero.create_network();
    alphazero.save_model(bestNet, bestPath, struct("settings", settings, "iteration", 0));
end
buffer = alphazero.load_replay_chunks(replayDirectory, settings.replayCapacity);
history = repmat(struct("iteration", 0, "samples", 0, "loss", NaN, ...
    "evaluation", struct()), settings.iterations, 1);

for iteration = 1:settings.iterations
    generated = struct("state", {}, "policy", {}, "legalMask", {}, "player", {}, "value", {});
    for gameIndex = 1:settings.selfPlayGamesPerIteration
        position = positions(mod(gameIndex - 1, numel(positions)) + 1);
        samples = alphazero.self_play(bestNet, position, settings);
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
            struct("settings", settings, "iteration", iteration, "evaluation", evaluation));
    end
    history(iteration) = struct("iteration", iteration, "samples", buffer.count(), ...
        "loss", metrics.loss, "evaluation", evaluation);
end
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
