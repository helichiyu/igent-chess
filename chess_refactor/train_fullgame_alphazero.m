function history = train_fullgame_alphazero(overrides)
%TRAIN_FULLGAME_ALPHAZERO Run resumable AlphaZero training from the opening.
if nargin < 1
    overrides = struct();
end
settings = apply_overrides(alphazero.fullgame_config(), overrides);
projectRoot = fileparts(mfilename("fullpath"));
modelDirectory = resolve_directory(projectRoot, settings.modelDirectory);
replayDirectory = resolve_directory(projectRoot, settings.replayDirectory);
logDirectory = resolve_directory(projectRoot, settings.logDirectory);
progressPath = fullfile(modelDirectory, "fullgame_progress.mat");
[completedIterations, rngState] = load_progress(progressPath);
if isempty(rngState)
    rng(settings.randomSeed, "twister");
else
    rng(rngState);
end
alphazero.prepare_execution(settings);

[bestNet, metadata] = alphazero.initialize_fullgame_model(projectRoot, settings);
if string(metadata.networkVersion) ~= string(settings.networkVersion)
    error("alphazero:IncompatibleModel", "The formal checkpoint has an unexpected network version.");
end
scenarios = alphazero.opening_scenarios();
buffer = alphazero.load_replay_chunks(replayDirectory, settings.replayCapacity);
history = repmat(history_item(), settings.iterations, 1);
fprintf("完整开局训练：本段 %d 轮，从第 %d 轮后继续。\n", ...
    settings.iterations, completedIterations);

for localIteration = 1:settings.iterations
    iteration = completedIterations + localIteration;
    timer = tic;
    fprintf("\n第 %d 轮开始（本段 %d/%d）。\n", iteration, localIteration, settings.iterations);
    generated = struct("state", {}, "policy", {}, "legalMask", {}, ...
        "player", {}, "value", {}, "scenarioId", {});
    metrics = repmat(game_metric(), settings.selfPlayGamesPerIteration, 1);
    for gameIndex = 1:settings.selfPlayGamesPerIteration
        scenario = scenarios(mod(gameIndex - 1, numel(scenarios)) + 1);
        [samples, ~, metrics(gameIndex)] = alphazero.self_play(bestNet, scenario, settings);
        generated = [generated samples]; %#ok<AGROW>
        fprintf("  自我对弈 %d/%d：%d 半回合，%s。\n", gameIndex, ...
            settings.selfPlayGamesPerIteration, metrics(gameIndex).plies, ...
            result_text(metrics(gameIndex).result));
    end
    buffer.add(generated);
    alphazero.save_replay_chunk(generated, replayDirectory, iteration);
    fprintf("  回放池：%d 个样本。\n", buffer.count());

    candidateNet = bestNet;
    optimizer = [];
    trainMetrics = struct("loss", NaN, "policyLoss", NaN, "valueLoss", NaN);
    for step = 1:settings.trainingStepsPerIteration
        [states, policies, values, masks] = buffer.sample(settings.batchSize);
        [candidateNet, optimizer, trainMetrics] = alphazero.train_step( ...
            candidateNet, states, policies, values, masks, optimizer, settings);
    end
    fprintf("  训练：%d 步，损失 %.4f（策略 %.4f，价值 %.4f）。\n", ...
        settings.trainingStepsPerIteration, trainMetrics.loss, ...
        trainMetrics.policyLoss, trainMetrics.valueLoss);
    evaluation = alphazero.evaluate_models(candidateNet, bestNet, scenarios, settings);
    fprintf("  开局评测：得分 %.3f，提升 %s。\n", ...
        evaluation.score, yes_no(evaluation.promoted));
    if evaluation.promoted
        bestNet = candidateNet;
        metadata = checkpoint_metadata(settings, scenarios, iteration, evaluation);
        alphazero.save_model(bestNet, fullfile(modelDirectory, "best_model.mat"), metadata);
        fprintf("  已保存新的统一最佳模型。\n");
    else
        fprintf("  保留当前统一最佳模型。\n");
    end
    elapsedSeconds = toc(timer);
    record = make_record(iteration, buffer.count(), trainMetrics, evaluation, ...
        metrics, elapsedSeconds, settings.networkVersion);
    history(localIteration) = record;
    alphazero.append_fullgame_log(logDirectory, record);
    save_progress(progressPath, iteration, rng, settings, metadata);
    fprintf("第 %d 轮完成，用时 %.1f 秒。\n", iteration, elapsedSeconds);
end
end

function item = history_item()
item = struct("iteration", 0, "samples", 0, "loss", NaN, "policyLoss", NaN, ...
    "valueLoss", NaN, "evaluation", struct(), "selfPlay", struct([]), ...
    "selfPlayGames", 0, "averagePlies", NaN, "maxPliesDraws", 0, ...
    "repetitionDraws", 0, "mctsSimulations", 0, "elapsedSeconds", NaN, ...
    "networkVersion", "");
end

function metric = game_metric()
metric = struct("scenarioId", "", "plies", 0, "result", "", "winner", 0, ...
    "repetitionDraw", false, "mctsSimulations", 0, "networkVersion", "");
end

function record = make_record(iteration, samples, trainMetrics, evaluation, games, elapsed, version)
record = history_item();
record.iteration = iteration;
record.samples = samples;
record.loss = trainMetrics.loss;
record.policyLoss = trainMetrics.policyLoss;
record.valueLoss = trainMetrics.valueLoss;
record.evaluation = evaluation;
record.selfPlay = games;
record.selfPlayGames = numel(games);
record.averagePlies = mean([games.plies]);
record.maxPliesDraws = sum(string({games.result}) == "max_plies");
record.repetitionDraws = sum([games.repetitionDraw]);
record.mctsSimulations = games(1).mctsSimulations;
record.elapsedSeconds = elapsed;
record.networkVersion = string(version);
end

function metadata = checkpoint_metadata(settings, scenarios, iteration, evaluation)
metadata = struct("networkVersion", settings.networkVersion, "iteration", iteration, ...
    "evaluation", evaluation, "settings", settings, ...
    "scenarioDataVersion", scenarios(1).source.dataVersion, ...
    "scenarioIds", string({scenarios.id}));
end

function [completedIterations, rngState] = load_progress(path)
completedIterations = 0;
rngState = [];
if ~isfile(path)
    return;
end
data = load(path, "completedIterations", "rngState");
completedIterations = data.completedIterations;
if isfield(data, "rngState")
    rngState = data.rngState;
end
end

function save_progress(path, completedIterations, rngState, settings, metadata)
networkVersion = settings.networkVersion;
save(path, "completedIterations", "rngState", "networkVersion", "settings", "metadata");
end

function directory = resolve_directory(projectRoot, directory)
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

function text = result_text(result)
switch string(result)
    case "checkmate"
        text = "将死";
    case "stalemate"
        text = "困毙";
    case "threefold_repetition"
        text = "三次重复和棋";
    case "max_plies"
        text = "达到步数上限和棋";
    otherwise
        text = string(result);
end
end

function text = yes_no(value)
if value
    text = "是";
else
    text = "否";
end
end
