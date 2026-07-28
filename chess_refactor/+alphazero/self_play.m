function [samples, outcome, metrics] = self_play(net, position, settings)
%SELF_PLAY Generate one MCTS-guided game and labeled training samples.
if nargin < 3 || isempty(settings)
    settings = alphazero.config();
end
state = alphazero.new_state(position.board, position.player, maximum_plies(position, settings));
samples = struct("state", {}, "policy", {}, "legalMask", {}, ...
    "player", {}, "value", {}, "scenarioId", {});
root = [];

while true
    outcome = alphazero.game_state(state);
    if outcome.isOver
        break;
    end
    [~, visitPolicy, root] = alphazero.mcts_search(net, state, settings, root, ...
        use_root_noise(settings));
    action = select_action(visitPolicy, state.ply, settings);
    sample = struct("state", alphazero.encode_state(state), ...
        "policy", visitPolicy, "legalMask", alphazero.legal_action_mask(state), ...
        "player", state.player, "value", single(0), ...
        "scenarioId", scenario_id(position));
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

function enabled = use_root_noise(settings)
enabled = isfield(settings, "selfPlayRootNoise") && settings.selfPlayRootNoise;
end

function id = scenario_id(position)
if isfield(position, "id")
    id = string(position.id);
else
    id = "validation";
end
end

for index = 1:numel(samples)
    if outcome.winner == 0
        samples(index).value = single(draw_value(settings));
    elseif outcome.winner == samples(index).player
        samples(index).value = single(1);
    else
        samples(index).value = single(-1);
    end
end

function value = draw_value(settings)
if isfield(settings, "drawValue")
    value = settings.drawValue;
else
    value = 0;
end
end
metrics = struct("scenarioId", scenario_id(position), "plies", state.ply, ...
    "result", outcome.result, "winner", outcome.winner, ...
    "repetitionDraw", outcome.result == "threefold_repetition", ...
    "mctsSimulations", settings.mctsSimulations, ...
    "networkVersion", network_version(settings));
end

function version = network_version(settings)
if isfield(settings, "networkVersion")
    version = string(settings.networkVersion);
else
    version = "endgame_validation_v1";
end
end

function plies = maximum_plies(position, settings)
plies = settings.maxPlies;
if isfield(position, "maxPlies")
    plies = min(plies, position.maxPlies);
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
