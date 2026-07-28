classdef TestFullgameTraining < matlab.unittest.TestCase
    methods (Test)
        function spatialNetworkProducesExpectedShapes(testCase)
            settings = alphazero.fullgame_config();
            net = alphazero.create_fullgame_network(settings);
            state = alphazero.new_state(xiangqi.new_board(), 1, settings.maxPlies);
            [logits, value] = alphazero.network_outputs(net, alphazero.encode_state(state));
            testCase.verifySize(logits, [8100 1]);
            testCase.verifySize(value, [1 1]);
            testCase.verifyTrue(isfinite(extractdata(value)));
        end

        function standardOpeningIsLegalAndHasExpectedMoves(testCase)
            scenario = alphazero.opening_scenarios();
            state = alphazero.new_state(scenario.board, scenario.player, scenario.maxPlies);
            testCase.verifyEqual(scenario.id, "standard_opening");
            testCase.verifyEqual(size(alphazero.legal_moves(state), 1), 44);
            testCase.verifyFalse(alphazero.game_state(state).isOver);
        end

        function fullgameDrawHasZeroValue(testCase)
            settings = alphazero.fullgame_preset("smoke");
            settings.useGPU = false;
            settings.maxPlies = 1;
            scenario = alphazero.opening_scenarios();
            [samples, outcome] = alphazero.self_play( ...
                alphazero.create_fullgame_network(settings), scenario, settings);
            testCase.verifyEqual(outcome.result, "max_plies");
            testCase.verifyEqual([samples.value], single(0));
        end

        function selfPlayAddsRootExplorationNoise(testCase)
            settings = alphazero.fullgame_preset("smoke");
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            state = alphazero.new_state(xiangqi.new_board(), 1, settings.maxPlies);
            net = alphazero.create_fullgame_network(settings);
            rng(10);
            [~, ~, deterministicRoot] = alphazero.mcts_search(net, state, settings);
            rng(10);
            [~, ~, noisyRoot] = alphazero.mcts_search(net, state, settings, [], true);
            testCase.verifyNotEqual(noisyRoot.Priors, deterministicRoot.Priors);
            testCase.verifyLessThan(abs(double(sum(noisyRoot.Priors)) - 1), 1e-6);
        end

        function allDrawEvaluationDoesNotPromote(testCase)
            settings = alphazero.fullgame_preset("smoke");
            settings.useGPU = false;
            settings.maxPlies = 1;
            settings.evaluationGamesPerPosition = 1;
            scenario = alphazero.opening_scenarios();
            net = alphazero.create_fullgame_network(settings);
            result = alphazero.evaluate_models(net, net, scenario, settings);
            testCase.verifyEqual(result.score, 0.5);
            testCase.verifyFalse(result.promoted);
        end

        function incompatibleCheckpointIsRejected(testCase)
            filePath = fullfile(tempdir, "alphazero_old_network_test.mat");
            cleanup = onCleanup(@()delete_if_present(filePath)); %#ok<NASGU>
            alphazero.save_model(alphazero.create_network(), filePath, struct());
            testCase.verifyError(@()alphazero.load_model(filePath, ...
                alphazero.fullgame_network_version()), "alphazero:IncompatibleModel");
        end

        function initializedCheckpointHasFullgameVersion(testCase)
            root = string(tempname);
            mkdir(root);
            cleanup = onCleanup(@()remove_folder(root)); %#ok<NASGU>
            settings = alphazero.fullgame_config();
            settings.modelDirectory = fullfile(root, "models");
            settings.replayDirectory = fullfile(root, "replay");
            [~, metadata] = alphazero.initialize_fullgame_model(root, settings);
            testCase.verifyEqual(string(metadata.networkVersion), ...
                alphazero.fullgame_network_version());
            testCase.verifyTrue(isfile(fullfile(settings.modelDirectory, "best_model.mat")));
        end

        function unifiedMoveIsLegal(testCase)
            settings = alphazero.fullgame_config();
            settings.useGPU = false;
            settings.mctsSimulations = 1;
            net = alphazero.create_fullgame_network(settings);
            board = xiangqi.new_board();
            counts = containers.Map("KeyType", "char", "ValueType", "double");
            counts(char(xiangqi.position_key(board, 1))) = 1;
            move = alphazero.select_unified_move(net, board, 1, counts, 0, settings);
            testCase.verifyTrue(any(ismember(xiangqi.legal_moves(board, 1), move, "rows")));
            testCase.verifyEqual(string(settings.networkVersion), ...
                alphazero.fullgame_network_version());
        end

        function segmentsResumeWithContinuousArtifacts(testCase)
            root = string(tempname);
            mkdir(root);
            cleanup = onCleanup(@()remove_folder(root)); %#ok<NASGU>
            settings = alphazero.fullgame_preset("smoke");
            settings.useGPU = false;
            settings.modelDirectory = fullfile(root, "models");
            settings.replayDirectory = fullfile(root, "replay");
            settings.logDirectory = fullfile(root, "logs");
            first = train_fullgame_alphazero(settings);
            second = train_fullgame_alphazero(settings);
            testCase.verifyEqual([first.iteration second.iteration], [1 2]);
            testCase.verifyTrue(isfile(fullfile(settings.replayDirectory, "replay_000001.mat")));
            testCase.verifyTrue(isfile(fullfile(settings.replayDirectory, "replay_000002.mat")));
            lines = readlines(fullfile(settings.logDirectory, "iteration_metrics.csv"));
            testCase.verifyEqual(numel(lines), 3);
        end

        function forwardAndBackwardAreFinite(testCase)
            settings = alphazero.fullgame_config();
            settings.useGPU = canUseGPU;
            if settings.useGPU
                alphazero.prepare_execution(settings);
            end
            net = alphazero.create_fullgame_network(settings);
            state = alphazero.new_state(xiangqi.new_board(), 1, settings.maxPlies);
            mask = alphazero.legal_action_mask(state);
            [~, optimizer, metrics] = alphazero.train_step(net, ...
                alphazero.encode_state(state), single(mask) ./ single(nnz(mask)), ...
                single(0), mask, [], settings);
            testCase.verifyEqual(optimizer.iteration, 1);
            testCase.verifyTrue(isfinite(metrics.loss));
        end
    end
end

function delete_if_present(path)
if isfile(path)
    delete(path);
end
end

function remove_folder(path)
if isfolder(path)
    rmdir(path, "s");
end
end
