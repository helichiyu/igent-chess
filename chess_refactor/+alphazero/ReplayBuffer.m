classdef ReplayBuffer < handle
    %REPLAYBUFFER Fixed-capacity storage for self-play samples.
    properties (SetAccess = private)
        Capacity
        Samples = struct("state", {}, "policy", {}, "legalMask", {}, ...
            "player", {}, "value", {}, "scenarioId", {})
    end

    methods
        function buffer = ReplayBuffer(capacity)
            validateattributes(capacity, {'numeric'}, {'scalar', 'integer', 'positive'});
            buffer.Capacity = capacity;
        end

        function add(buffer, samples)
            if isempty(samples)
                return;
            end
            buffer.Samples = [buffer.Samples samples];
            overflow = numel(buffer.Samples) - buffer.Capacity;
            if overflow > 0
                buffer.Samples(1:overflow) = [];
            end
        end

        function count = count(buffer)
            count = numel(buffer.Samples);
        end

        function [states, policies, values, masks] = sample(buffer, batchSize)
            count = min(batchSize, buffer.count());
            if count == 0
                error("alphazero:EmptyReplayBuffer", "Cannot sample from an empty replay buffer.");
            end
            indices = randperm(buffer.count(), count);
            selected = buffer.Samples(indices);
            states = cat(4, selected.state);
            policies = cat(2, selected.policy);
            values = reshape(single([selected.value]), 1, []);
            masks = cat(2, selected.legalMask);
        end
    end
end
