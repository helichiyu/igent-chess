function [move, detail] = choose_move(board, player, modelPath)
%CHOOSE_MOVE Pick a legal move using a compatible saved network or fallback scoring.
% The fallback is deterministic material-and-capture scoring so the GUI works
% even if the historical neural-network file cannot be loaded by this MATLAB.
if nargin < 3 || isempty(modelPath)
    modelPath = "model5.mat";
end
moves = xiangqi.legal_moves(board, player);
detail = struct("source", "heuristic", "scores", [], "modelError", "");
if isempty(moves)
    move = zeros(0, 4);
    return;
end
scores = -inf(size(moves, 1), 1);
net = [];
if isfile(modelPath)
    try
        data = load(modelPath, "net");
        net = data.net;
    catch exception
        detail.modelError = string(exception.message);
    end
end
for index = 1:size(moves, 1)
    candidate = moves(index, :);
    nextBoard = xiangqi.apply_move(board, candidate);
    score = fallback_score(board, nextBoard, player, candidate);
    if ~isempty(net)
        try
            output = predict(net, reshape(board, 10, 9, 1, 1), ...
                reshape(candidate, 4, 1, 1, 1));
            score = double(extractdata(output(2)));
            detail.source = "model";
        catch exception
            detail.modelError = string(exception.message);
            net = [];
        end
    end
    scores(index) = score;
end
[~, best] = max(scores);
move = moves(best, :);
detail.scores = scores;
end

function score = fallback_score(board, nextBoard, player, move)
values = [10000 20 20 45 90 45 10];
captured = board(move(3), move(4));
captureValue = 0;
if captured > 0
    captureValue = values(mod(captured - 1, 7) + 1);
end
material = board_material(nextBoard, player, values) - board_material(nextBoard, -player, values);
score = material + 2 * captureValue;
if xiangqi.is_in_check(nextBoard, -player)
    score = score + 50;
end
end

function total = board_material(board, player, values)
if player == 1
    pieces = board(board >= 1 & board <= 7);
else
    pieces = board(board >= 8 & board <= 14) - 7;
end
total = sum(values(pieces));
end
