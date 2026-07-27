function settings = fullgame_preset(name)
%FULLGAME_PRESET Return conservative resumable training segment settings.
settings = alphazero.fullgame_config();
switch lower(string(name))
    case "smoke"
        settings.mctsSimulations = 2;
        settings.selfPlayGamesPerIteration = 1;
        settings.maxPlies = 20;
        settings.trainingStepsPerIteration = 1;
        settings.evaluationGamesPerPosition = 1;
    case "short"
        settings.iterations = 2;
        settings.mctsSimulations = 8;
        settings.selfPlayGamesPerIteration = 2;
        settings.maxPlies = 120;
        settings.trainingStepsPerIteration = 10;
    case "medium"
        settings.iterations = 10;
        settings.mctsSimulations = 16;
        settings.selfPlayGamesPerIteration = 4;
        settings.maxPlies = 200;
        settings.trainingStepsPerIteration = 20;
    case "overnight"
        settings.iterations = 30;
        settings.mctsSimulations = 32;
        settings.selfPlayGamesPerIteration = 8;
        settings.maxPlies = 300;
        settings.trainingStepsPerIteration = 40;
    otherwise
        error("alphazero:UnknownPreset", "Unknown full-game preset: %s.", string(name));
end
end
