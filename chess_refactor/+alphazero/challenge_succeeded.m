function succeeded = challenge_succeeded(scenario, outcome)
%CHALLENGE_SUCCEEDED Decide whether a scenario achieved its configured result.
switch string(scenario.expectedResult)
    case "red_win"
        succeeded = outcome.winner == 1;
    case "black_win"
        succeeded = outcome.winner == -1;
    case "draw"
        succeeded = outcome.winner == 0;
    otherwise
        error("alphazero:InvalidExpectedResult", "Scenario expected result is invalid.");
end
end
