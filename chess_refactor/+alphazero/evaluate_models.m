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
for scenarioIndex = 1:numel(scenarios)
    scenario = scenarios(scenarioIndex);
    scenarioScore = 0;
    wins = 0;
    draws = 0;
    losses = 0;
    plies = 0;
    repetitions = 0;
    for gameIndex = 1:settings.evaluationGamesPerPosition %#ok<NASGU>
        outcome = alphazero.play_game(candidateNet, bestNet, scenario, settings);
        [gameScore, won, drawn] = candidate_score(outcome, 1);
        scenarioScore = scenarioScore + gameScore;
        wins = wins + won;
        draws = draws + drawn;
        losses = losses + ~(won || drawn);
        plies = plies + outcome.plies;
        repetitions = repetitions + (outcome.result == "threefold_repetition");
        games = games + 1;
        outcome = alphazero.play_game(bestNet, candidateNet, scenario, settings);
        [gameScore, won, drawn] = candidate_score(outcome, -1);
        scenarioScore = scenarioScore + gameScore;
        wins = wins + won;
        draws = draws + drawn;
        losses = losses + ~(won || drawn);
        plies = plies + outcome.plies;
        repetitions = repetitions + (outcome.result == "threefold_repetition");
        games = games + 1;
    end
    scenarioGames = 2 * settings.evaluationGamesPerPosition;
    perScenario(scenarioIndex) = struct("id", scenario.id, "games", scenarioGames, ...
        "candidateScore", scenarioScore / scenarioGames, "wins", wins, ...
        "draws", draws, "losses", losses, "averagePlies", plies / scenarioGames, ...
        "repetitionDraws", repetitions);
    score = score + scenarioScore;
end
result = struct("score", score / games, "games", games, ...
    "promoted", meets_all_thresholds(perScenario, settings), ...
    "perScenario", perScenario);
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
