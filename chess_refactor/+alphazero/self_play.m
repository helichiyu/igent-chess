function [samples, outcome] = self_play(net, position, settings)
%SELF_PLAY Generate one MCTS-guided game and labeled training samples.
if nargin < 3 || isempty(settings)
    settings = alphazero.config();
end
state = alphazero.new_state(position.board, position.player, settings.maxPlies);
samples = struct("state", {}, "policy", {}, "legalMask", {}, ...
    "player", {}, "value", {});
root = [];

while true
    outcome = alphazero.game_state(state);
    if outcome.isOver
        break;
    end
    [~, visitPolicy, root] = alphazero.mcts_search(net, state, settings, root);
    action = select_action(visitPolicy, state.ply, settings);
    sample = struct("state", alphazero.encode_state(state), ...
        "policy", visitPolicy, "legalMask", alphazero.legal_action_mask(state), ...
        "player", state.player, "value", single(0));
    samples(end + 1) = sample; %#ok<AGROW>

    edge = find(root.Actions == action, 1);
    if isempty(edge)
        error("alphazero:InvalidSearchPolicy", "Selected action is not present at the search root.");
    end
    if isempty(root.Children{edge})
        nextState = alphazero.next_state(state, root.Moves(edge, :));
        root.Children{edge} = alphazero.MCTSNode(nextState);
    end
    root = root.Children{edge};
    state = root.State;
end

for index = 1:numel(samples)
    if outcome.winner == 0
        samples(index).value = single(0);
    elseif outcome.winner == samples(index).player
        samples(index).value = single(1);
    else
        samples(index).value = single(-1);
    end
end
end

function action = select_action(policy, ply, settings)
if ply >= settings.temperaturePlies || settings.selfPlayTemperature <= 0
    [~, action] = max(policy);
    return;
end
weights = double(policy) .^ (1 / settings.selfPlayTemperature);
weights = weights ./ sum(weights);
threshold = rand();
action = find(cumsum(weights) >= threshold, 1);
end
