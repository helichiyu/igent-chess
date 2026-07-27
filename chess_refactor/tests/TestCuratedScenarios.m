classdef TestCuratedScenarios < matlab.unittest.TestCase
    methods (Test)
        function allImportedScenariosArePlayable(testCase)
            scenarios = alphazero.curated_scenarios();
            testCase.verifyEqual(numel(scenarios), 9);
            expectedIds = ["qi-xing-ju-hui" "ma-yue-tan-xi" "pao-zha-liang-lang" ...
                "xiao-zheng-dong" "qiu-yin-jiang-long" "da-jiu-lian-huan" ...
                "dai-zi-ru-chao" "zheng-xi" "ye-ma-cao-tian"];
            testCase.verifyEqual(string({scenarios.id}), expectedIds);
            for index = 1:numel(scenarios)
                [valid, message] = alphazero.validate_scenario(scenarios(index));
                testCase.verifyTrue(valid, scenarios(index).id + ": " + message);
                state = alphazero.new_state(scenarios(index).board, ...
                    scenarios(index).player, scenarios(index).maxPlies);
                testCase.verifyNotEmpty(alphazero.legal_moves(state), scenarios(index).id);
            end
        end

        function expectedResultsAndSourcesAreLocked(testCase)
            scenarios = alphazero.curated_scenarios();
            results = string({scenarios.expectedResult});
            testCase.verifyEqual(results(5), "draw");
            testCase.verifyEqual(results([1:4 6:9]), repmat("red_win", 1, 8));
            for index = 1:numel(scenarios)
                testCase.verifyEqual(scenarios(index).source.repository, "ZDSxbj/ChineseChess");
                testCase.verifyEqual(scenarios(index).source.dataVersion, "curated-v1");
                testCase.verifyEqual(scenarios(index).maxPlies, 120);
            end
        end
    end
end
