function result = evaluate_models(candidateNet, bestNet, positions, settings)
%EVALUATE_MODELS Score candidate versus best with red/black roles exchanged.
if nargin < 3 || isempty(positions)
    positions = alphazero.initial_positions();
end
if nargin < 4 || isempty(settings)
    settings = alphazero.config();
end
score = 0;
games = 0;
for positionIndex = 1:numel(positions)
    for gameIndex = 1:settings.evaluationGamesPerPosition %#ok<NASGU>
        outcome = alphazero.play_game(candidateNet, bestNet, positions(positionIndex), settings);
        score = score + score_for_player(outcome, 1);
        games = games + 1;
        outcome = alphazero.play_game(bestNet, candidateNet, positions(positionIndex), settings);
        score = score + score_for_player(outcome, -1);
        games = games + 1;
    end
end
result = struct("score", score / games, "games", games, ...
    "promoted", score / games >= settings.promotionScore);
end

function score = score_for_player(outcome, player)
if outcome.winner == 0
    score = 0.5;
elseif outcome.winner == player
    score = 1;
else
    score = 0;
end
end
