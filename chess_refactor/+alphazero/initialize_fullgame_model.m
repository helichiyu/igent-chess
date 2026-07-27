function [net, metadata] = initialize_fullgame_model(projectRoot, settings)
%INITIALIZE_FULLGAME_MODEL Create the unified checkpoint after safe archival.
if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = fileparts(fileparts(mfilename("fullpath")));
end
if nargin < 2 || isempty(settings)
    settings = alphazero.fullgame_config();
end
projectRoot = string(projectRoot);
modelDirectory = resolve_directory(projectRoot, settings.modelDirectory);
replayDirectory = resolve_directory(projectRoot, settings.replayDirectory);
bestPath = fullfile(modelDirectory, "best_model.mat");

if isfile(bestPath)
    try
        [net, metadata] = alphazero.load_model(bestPath, settings.networkVersion);
        return;
    catch exception
        if exception.identifier ~= "alphazero:IncompatibleModel"
            rethrow(exception);
        end
    end
end

archive_validation_artifacts(projectRoot, modelDirectory, replayDirectory);
net = alphazero.create_fullgame_network(settings);
metadata = struct("networkVersion", settings.networkVersion, ...
    "createdAt", string(datetime("now", Format="yyyy-MM-dd HH:mm:ss")), ...
    "iteration", 0, "settings", settings, "scenarioDataVersion", "opening_v1", ...
    "scenarioIds", "standard_opening");
alphazero.save_model(net, bestPath, metadata);
end

function archive_validation_artifacts(projectRoot, modelDirectory, replayDirectory)
archiveDirectory = fullfile(modelDirectory, "archive", "endgame_validation");
sources = [fullfile(modelDirectory, "best_model.mat"), ...
    fullfile(modelDirectory, "training_progress.mat"), ...
    fullfile(projectRoot, "replay")];
modelReplay = dir(fullfile(modelDirectory, "replay_*.mat"));
present = isfile(sources(1)) || isfile(sources(2)) || isfolder(sources(3)) || ...
    ~isempty(modelReplay);
if ~present
    return;
end
if isfolder(archiveDirectory)
    error("alphazero:ArchiveExists", ...
        "Validation artifact archive already exists: %s", archiveDirectory);
end
if isfolder(replayDirectory) && replayDirectory == sources(3)
    error("alphazero:InvalidReplayDirectory", ...
        "Full-game replay directory must differ from the validation replay directory.");
end
mkdir(archiveDirectory);
for index = 1:numel(sources)
    source = sources(index);
    if isfile(source) || isfolder(source)
        [ok, message] = movefile(source, archiveDirectory);
        if ~ok
            error("alphazero:ArchiveFailed", "Could not archive %s: %s", source, message);
        end
    end
end
for index = 1:numel(modelReplay)
    source = fullfile(modelReplay(index).folder, modelReplay(index).name);
    [ok, message] = movefile(source, archiveDirectory);
    if ~ok
        error("alphazero:ArchiveFailed", "Could not archive %s: %s", source, message);
    end
end
end

function directory = resolve_directory(projectRoot, directory)
directory = string(directory);
if isempty(regexp(directory, "^[A-Za-z]:[\\\\/]", "once")) && ...
        ~startsWith(directory, "\\\\")
    directory = fullfile(projectRoot, directory);
end
end
