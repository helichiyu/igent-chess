classdef TestCuratedTraining < matlab.unittest.TestCase
    methods (Test)
        function selfPlayRetainsScenarioIdentifier(testCase)
            rng(9);
            scenarios = alphazero.curated_scenarios();
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            settings.maxPlies = 1;
            [samples, outcome, metrics] = alphazero.self_play( ...
                alphazero.create_network(), scenarios(1), settings);
            testCase.verifyTrue(outcome.isOver);
            testCase.verifyNotEmpty(samples);
            testCase.verifyEqual(string({samples.scenarioId}), ...
                repmat(scenarios(1).id, 1, numel(samples)));
            testCase.verifyEqual(metrics.scenarioId, scenarios(1).id);
            testCase.verifyEqual(metrics.plies, 1);
        end

        function challengeOutcomeMatchesConfiguredGoal(testCase)
            scenarios = alphazero.curated_scenarios();
            win = struct("winner", 1);
            draw = struct("winner", 0);
            testCase.verifyTrue(alphazero.challenge_succeeded(scenarios(1), win));
            testCase.verifyFalse(alphazero.challenge_succeeded(scenarios(1), draw));
            testCase.verifyTrue(alphazero.challenge_succeeded(scenarios(5), draw));
            testCase.verifyFalse(alphazero.challenge_succeeded(scenarios(5), win));
        end

        function scenarioThresholdPreventsAggregateOnlyPromotion(testCase)
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            settings.maxPlies = 1;
            settings.evaluationGamesPerPosition = 1;
            settings.promotionScore = 0;
            settings.scenarioPromotionThresholds = struct("default", 1.1);
            scenarios = alphazero.curated_scenarios();
            result = alphazero.evaluate_models( ...
                alphazero.create_network(), alphazero.create_network(), scenarios(1), settings);
            testCase.verifyFalse(result.promoted);
        end
    end
end
