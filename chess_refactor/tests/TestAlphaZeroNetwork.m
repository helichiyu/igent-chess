classdef TestAlphaZeroNetwork < matlab.unittest.TestCase
    methods (Test)
        function networkProducesExpectedShapes(testCase)
            net = alphazero.create_network();
            position = alphazero.initial_positions();
            state = alphazero.new_state(position(1).board, position(1).player);
            encoded = alphazero.encode_state(state);
            [logits, value] = alphazero.network_outputs(net, encoded);
            testCase.verifySize(logits, [8100 1]);
            testCase.verifySize(value, [1 1]);
            testCase.verifyTrue(isfinite(extractdata(value)));
        end

        function maskedPolicyIsFiniteAndLegal(testCase)
            net = alphazero.create_network();
            position = alphazero.initial_positions();
            state = alphazero.new_state(position(1).board, position(1).player);
            [policy, value] = alphazero.evaluate_network(net, state, false);
            mask = alphazero.legal_action_mask(state);
            testCase.verifyEqual(sum(policy), single(1), AbsTol=1e-6);
            testCase.verifyEqual(policy(~mask), zeros(nnz(~mask), 1, "like", policy));
            testCase.verifyGreaterThanOrEqual(value, -1);
            testCase.verifyLessThanOrEqual(value, 1);
        end

        function oneTrainingStepHasFiniteLoss(testCase)
            net = alphazero.create_network();
            position = alphazero.initial_positions();
            state = alphazero.new_state(position(1).board, position(1).player);
            states = alphazero.encode_state(state);
            legalMasks = alphazero.legal_action_mask(state);
            targetPolicies = single(legalMasks) ./ single(nnz(legalMasks));
            targetValues = single(1);
            settings = alphazero.config();
            settings.useGPU = false;
            [~, optimizer, metrics] = alphazero.train_step(net, states, ...
                targetPolicies, targetValues, legalMasks, [], settings);
            testCase.verifyEqual(optimizer.iteration, 1);
            testCase.verifyTrue(isfinite(metrics.loss));
            testCase.verifyTrue(isfinite(metrics.policyLoss));
            testCase.verifyTrue(isfinite(metrics.valueLoss));
        end
    end
end
