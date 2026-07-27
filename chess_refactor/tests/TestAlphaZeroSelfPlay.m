classdef TestAlphaZeroSelfPlay < matlab.unittest.TestCase
    methods (Test)
        function shortGameProducesValidSamples(testCase)
            rng(7);
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 2;
            settings.maxPlies = 2;
            positions = alphazero.initial_positions();
            [samples, outcome] = alphazero.self_play( ...
                alphazero.create_network(), positions(4), settings);
            testCase.verifyNotEmpty(samples);
            testCase.verifyTrue(outcome.isOver);
            for index = 1:numel(samples)
                testCase.verifyEqual(sum(samples(index).policy), single(1), AbsTol=1e-6);
                testCase.verifyTrue(all(ismember(samples(index).value, single([-1 0 1]))));
                testCase.verifyTrue(all(samples(index).policy(~samples(index).legalMask) == 0));
                testCase.verifyEqual(samples(index).scenarioId, "validation");
            end
        end

        function replayCapacityAndSamplingAreBounded(testCase)
            rng(8);
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            settings.maxPlies = 2;
            positions = alphazero.initial_positions();
            samples = alphazero.self_play(alphazero.create_network(), positions(4), settings);
            buffer = alphazero.ReplayBuffer(3);
            buffer.add([samples samples]);
            testCase.verifyLessThanOrEqual(buffer.count(), 3);
            [states, policies, values, masks] = buffer.sample(2);
            testCase.verifyEqual(size(states, 4), min(2, buffer.count()));
            testCase.verifyEqual(size(policies), size(masks));
            testCase.verifyEqual(size(values, 2), min(2, buffer.count()));
        end
    end
end
