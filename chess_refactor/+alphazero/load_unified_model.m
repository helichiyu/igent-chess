function [net, metadata, settings] = load_unified_model()
%LOAD_UNIFIED_MODEL Load the one formal full-game policy-value checkpoint.
projectRoot = fileparts(fileparts(mfilename("fullpath")));
path = fullfile(projectRoot, "models", "best_model.mat");
settings = alphazero.fullgame_config();
[net, metadata] = alphazero.load_model(path, settings.networkVersion);
end
