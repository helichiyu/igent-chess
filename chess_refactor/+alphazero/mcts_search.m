function [move, visitPolicy, root] = mcts_search(net, state, settings, root, addRootNoise)
%MCTS_SEARCH Search one state with PUCT and a policy-value network.
if nargin < 3 || isempty(settings)
    settings = alphazero.config();
end
if nargin < 4 || isempty(root)
    root = alphazero.MCTSNode(state);
end
if nargin < 5 || isempty(addRootNoise)
    addRootNoise = false;
end
validateattributes(settings.mctsSimulations, {'numeric'}, {'scalar', 'integer', 'positive'});

visitPolicy = zeros(8100, 1, "single");
outcome = alphazero.game_state(root.State);
if outcome.isOver
    move = zeros(0, 4);
    return;
end
if ~root.Expanded
    [~, rootValue] = expand_node(root, net, settings.useGPU); %#ok<ASGLU>
end
if addRootNoise
    apply_root_noise(root, settings);
end

for simulation = 1:settings.mctsSimulations
    node = root;
    pathNodes = cell(0, 1);
    pathEdges = zeros(0, 1);
    while true
        edge = select_edge(node, settings.puctConstant);
        pathNodes{end + 1, 1} = node; %#ok<AGROW>
        pathEdges(end + 1, 1) = edge; %#ok<AGROW>
        if isempty(node.Children{edge})
            childState = alphazero.next_state(node.State, node.Moves(edge, :));
            node.Children{edge} = alphazero.MCTSNode(childState);
        end
        node = node.Children{edge};
        outcome = alphazero.game_state(node.State);
        if outcome.isOver
            leafValue = terminal_value(outcome, node.State.player);
            break;
        end
        if ~node.Expanded
            [~, leafValue] = expand_node(node, net, settings.useGPU);
            break;
        end
    end
    backpropagate(pathNodes, pathEdges, leafValue);
end

counts = root.VisitCounts;
visitPolicy(root.Actions) = single(counts ./ sum(counts));
[~, bestEdge] = max(counts);
move = root.Moves(bestEdge, :);
end

function apply_root_noise(root, settings)
if ~isfield(settings, "dirichletAlpha") || ~isfield(settings, "dirichletFraction")
    error("alphazero:MissingExplorationSetting", ...
        "Dirichlet exploration requires alpha and fraction settings.");
end
validateattributes(settings.dirichletAlpha, {'numeric'}, {'scalar', 'positive'});
validateattributes(settings.dirichletFraction, {'numeric'}, {'scalar', '>=', 0, '<=', 1});
noise = randg(settings.dirichletAlpha, numel(root.Priors), 1);
noise = noise ./ sum(noise);
root.Priors = single((1 - settings.dirichletFraction) .* double(root.Priors) + ...
    settings.dirichletFraction .* noise);
end

function [policy, value] = expand_node(node, net, useGPU)
[policy, value] = alphazero.evaluate_network(net, node.State, useGPU);
moves = alphazero.legal_moves(node.State);
actions = zeros(size(moves, 1), 1);
for index = 1:size(moves, 1)
    actions(index) = alphazero.encode_move(moves(index, :), node.State.player);
end
node.expand(moves, actions, policy(actions));
value = double(value);
end

function edge = select_edge(node, puctConstant)
meanValues = node.ValueSums ./ max(1, node.VisitCounts);
exploration = puctConstant .* double(node.Priors) .* ...
    sqrt(sum(node.VisitCounts) + 1) ./ (1 + node.VisitCounts);
[~, edge] = max(meanValues + exploration);
end

function backpropagate(pathNodes, pathEdges, leafValue)
value = double(leafValue);
for index = numel(pathNodes):-1:1
    value = -value;
    node = pathNodes{index};
    edge = pathEdges(index);
    node.VisitCounts(edge) = node.VisitCounts(edge) + 1;
    node.ValueSums(edge) = node.ValueSums(edge) + value;
end
end

function value = terminal_value(outcome, player)
if outcome.winner == 0
    value = 0;
elseif outcome.winner == player
    value = 1;
else
    value = -1;
end
end
