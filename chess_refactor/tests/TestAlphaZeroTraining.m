classdef TestAlphaZeroTraining < matlab.unittest.TestCase
    methods (Test)
        function modelEvaluationUsesBothColors(testCase)
            settings = alphazero.config();
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            settings.maxPlies = 1;
            settings.evaluationGamesPerPosition = 1;
            positions = alphazero.curated_scenarios();
            net = alphazero.create_network();
            result = alphazero.evaluate_models(net, net, positions(4), settings);
            testCase.verifyEqual(result.games, 2);
            testCase.verifyGreaterThanOrEqual(result.score, 0);
            testCase.verifyLessThanOrEqual(result.score, 1);
            testCase.verifyEqual(result.perScenario.id, positions(4).id);
        end

        function minimalTrainingLoopWritesCheckpoint(testCase)
            root = tempname;
            mkdir(root);
            cleanup = onCleanup(@()rmdir(root, "s")); %#ok<NASGU>
            overrides = struct("useGPU", false, "iterations", 1, ...
                "selfPlayGamesPerIteration", 1, "mctsSimulations", 1, ...
                "maxPlies", 1, "trainingStepsPerIteration", 1, "batchSize", 1, ...
                "evaluationGamesPerPosition", 1, "modelDirectory", fullfile(root, "models"), ...
                "replayDirectory", fullfile(root, "replay"));
            history = train_endgame_alphazero(overrides);
            testCase.verifyEqual(numel(history), 1);
            testCase.verifyGreaterThan(history.samples, 0);
            testCase.verifyTrue(isfinite(history.loss));
            testCase.verifyTrue(isfile(fullfile(root, "models", "best_model.mat")));
            [~, metadata] = alphazero.load_model(fullfile(root, "models", "best_model.mat"));
            testCase.verifyEqual(metadata.scenarioDataVersion, "curated-v1");
            testCase.verifyEqual(numel(metadata.scenarioIds), 9);
        end

        function trainingResumesWithContinuousIterationNumbers(testCase)
            root = tempname;
            mkdir(root);
            cleanup = onCleanup(@()rmdir(root, "s")); %#ok<NASGU>
            overrides = struct("useGPU", false, "iterations", 1, ...
                "selfPlayGamesPerIteration", 1, "mctsSimulations", 1, ...
                "maxPlies", 1, "trainingStepsPerIteration", 1, "batchSize", 1, ...
                "evaluationGamesPerPosition", 1, "modelDirectory", fullfile(root, "models"), ...
                "replayDirectory", fullfile(root, "replay"));
            first = train_endgame_alphazero(overrides);
            second = train_endgame_alphazero(overrides);
            testCase.verifyEqual(first.iteration, 1);
            testCase.verifyEqual(second.iteration, 2);
            testCase.verifyTrue(isfile(fullfile(root, "models", "training_progress.mat")));
            testCase.verifyTrue(isfile(fullfile(root, "replay", "replay_000001.mat")));
            testCase.verifyTrue(isfile(fullfile(root, "replay", "replay_000002.mat")));
        end
    end
end
