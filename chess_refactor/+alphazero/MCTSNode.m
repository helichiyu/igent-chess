classdef MCTSNode < handle
    %MCTSNODE Mutable statistics for one Monte Carlo tree-search state.
    properties
        State
        Expanded = false
        Moves = zeros(0, 4)
        Actions = zeros(0, 1)
        Priors = zeros(0, 1, "single")
        VisitCounts = zeros(0, 1)
        ValueSums = zeros(0, 1)
        Children = cell(0, 1)
    end

    methods
        function node = MCTSNode(state)
            node.State = state;
        end

        function expand(node, moves, actions, priors)
            node.Moves = moves;
            node.Actions = reshape(actions, [], 1);
            node.Priors = reshape(single(priors), [], 1);
            count = numel(node.Actions);
            node.VisitCounts = zeros(count, 1);
            node.ValueSums = zeros(count, 1);
            node.Children = cell(count, 1);
            node.Expanded = true;
        end
    end
end
