function [valid, message] = validate_scenario(scenario)
%VALIDATE_SCENARIO Verify scenario fields and rule-engine playability.
valid = false;
message = "";
required = ["id" "name" "board" "player" "challengePlayer" ...
    "expectedResult" "maxPlies" "source"];
if ~isstruct(scenario) || ~all(isfield(scenario, required))
    message = "Scenario is missing required fields.";
    return;
end
if ~isequal(size(scenario.board), [10 9]) || any(~ismember(scenario.board(:), 0:14))
    message = "Board must be a 10-by-9 matrix of piece codes.";
    return;
end
if ~ismember(scenario.player, [-1 1]) || ~ismember(scenario.challengePlayer, [-1 1])
    message = "Player fields must be 1 or -1.";
    return;
end
if ~ismember(string(scenario.expectedResult), ["red_win" "black_win" "draw"])
    message = "Expected result is invalid.";
    return;
end
if ~isscalar(scenario.maxPlies) || scenario.maxPlies <= 0 || mod(scenario.maxPlies, 1) ~= 0
    message = "Maximum plies must be a positive integer.";
    return;
end
if ~valid_piece_placement(scenario.board)
    message = "Piece placement violates palace, river, or facing-general constraints.";
    return;
end
state = alphazero.new_state(scenario.board, scenario.player, scenario.maxPlies);
outcome = alphazero.game_state(state);
if outcome.isOver
    message = "Starting position is terminal.";
    return;
end
if isempty(alphazero.legal_moves(state))
    message = "Starting player has no legal move.";
    return;
end
valid = true;
end

function valid = valid_piece_placement(board)
valid = nnz(board == 1) == 1 && nnz(board == 8) == 1;
if ~valid
    return;
end
[redRow, redCol] = find(board == 1);
[blackRow, blackCol] = find(board == 8);
valid = in_palace(redRow, redCol, 1) && in_palace(blackRow, blackCol, -1);
if ~valid
    return;
end
advisors = find(board == 2 | board == 9);
for index = reshape(advisors, 1, [])
    [row, col] = ind2sub(size(board), index);
    player = 1;
    if board(row, col) == 9, player = -1; end
    if ~in_palace(row, col, player)
        valid = false;
        return;
    end
end
redBishops = find(board == 3);
blackBishops = find(board == 10);
if any(arrayfun(@(index) ind2sub_row(index) < 6, redBishops)) || ...
        any(arrayfun(@(index) ind2sub_row(index) > 5, blackBishops))
    valid = false;
    return;
end
if redCol == blackCol && all(board(min(redRow, blackRow)+1:max(redRow, blackRow)-1, redCol) == 0)
    valid = false;
end
end

function result = in_palace(row, col, player)
if player == 1
    result = row >= 8 && row <= 10 && col >= 4 && col <= 6;
else
    result = row >= 1 && row <= 3 && col >= 4 && col <= 6;
end
end

function row = ind2sub_row(index)
[row, ~] = ind2sub([10 9], index);
end
