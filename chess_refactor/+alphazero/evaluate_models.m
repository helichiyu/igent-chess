function result = evaluate_models(candidateNet, bestNet, scenarios, settings)
%EVALUATE_MODELS Compare models and retain separate metrics per scenario.
if nargin < 3 || isempty(scenarios)
    scenarios = alphazero.curated_scenarios();
end
if nargin < 4 || isempty(settings)
    settings = alphazero.config();
end
perScenario = repmat(struct("id", "", "games", 0, "candidateScore", 0, ...
    "wins", 0, "draws", 0, "losses", 0, "averagePlies", 0, ...
    "repetitionDraws", 0), numel(scenarios), 1);
score = 0;
games = 0;
totalGames = 2 * settings.evaluationGamesPerPosition * numel(scenarios);
for scenarioIndex = 1:numel(scenarios)
    scenario = scenarios(scenarioIndex);
    scenarioScore = 0;
    wins = 0;
    draws = 0;
    losses = 0;
    plies = 0;
    repetitions = 0;
    for gameIndex = 1:settings.evaluationGamesPerPosition %#ok<NASGU>
        fprintf("  评测 %d/%d：候选执红，正在搜索...\n", games + 1, totalGames);
        outcome = alphazero.play_game(candidateNet, bestNet, scenario, settings);
        [gameScore, won, drawn] = candidate_score(outcome, 1);
        scenarioScore = scenarioScore + gameScore;
        wins = wins + won;
        draws = draws + drawn;
        losses = losses + ~(won || drawn);
        plies = plies + outcome.plies;
        repetitions = repetitions + (outcome.result == "threefold_repetition");
        games = games + 1;
        fprintf("    完成：%d 半回合，%s。\n", outcome.plies, result_text(outcome.result));
        fprintf("  评测 %d/%d：候选执黑，正在搜索...\n", games + 1, totalGames);
        outcome = alphazero.play_game(bestNet, candidateNet, scenario, settings);
        [gameScore, won, drawn] = candidate_score(outcome, -1);
        scenarioScore = scenarioScore + gameScore;
        wins = wins + won;
        draws = draws + drawn;
        losses = losses + ~(won || drawn);
        plies = plies + outcome.plies;
        repetitions = repetitions + (outcome.result == "threefold_repetition");
        games = games + 1;
        fprintf("    完成：%d 半回合，%s。\n", outcome.plies, result_text(outcome.result));
    end
    scenarioGames = 2 * settings.evaluationGamesPerPosition;
    perScenario(scenarioIndex) = struct("id", scenario.id, "games", scenarioGames, ...
        "candidateScore", scenarioScore / scenarioGames, "wins", wins, ...
        "draws", draws, "losses", losses, "averagePlies", plies / scenarioGames, ...
        "repetitionDraws", repetitions);
    score = score + scenarioScore;
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
result = struct("score", score / games, "games", games, ...
    "promoted", meets_all_thresholds(perScenario, settings), ...
    "perScenario", perScenario, "mctsSimulations", settings.mctsSimulations, ...
    "networkVersion", network_version(settings));
end

function version = network_version(settings)
if isfield(settings, "networkVersion")
    version = string(settings.networkVersion);
else
    version = "endgame_validation_v1";
end
end

function promoted = meets_all_thresholds(perScenario, settings)
for index = 1:numel(perScenario)
    threshold = settings.promotionScore;
    if isfield(settings, "scenarioPromotionThresholds")
        field = matlab.lang.makeValidName(perScenario(index).id);
        if isfield(settings.scenarioPromotionThresholds, field)
            threshold = settings.scenarioPromotionThresholds.(field);
        elseif isfield(settings.scenarioPromotionThresholds, "default")
            threshold = settings.scenarioPromotionThresholds.default;
        end
    end
    if perScenario(index).candidateScore < threshold
        promoted = false;
        return;
    end
end
promoted = true;
end

function [score, won, drawn] = candidate_score(outcome, player)
if outcome.winner == 0
    score = 0.5;
    won = false;
    drawn = true;
elseif outcome.winner == player
    score = 1;
    won = true;
    drawn = false;
else
    score = 0;
    won = false;
    drawn = false;
end
end
