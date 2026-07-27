function [net, metadata] = load_model(filePath, expectedNetworkVersion)
%LOAD_MODEL Load a policy-value network and its experiment metadata.
if nargin < 2
    expectedNetworkVersion = "";
end
data = load(filePath, "net", "metadata");
net = data.net;
if isfield(data, "metadata")
    metadata = data.metadata;
else
    metadata = struct();
end
if strlength(string(expectedNetworkVersion)) > 0
    if ~isfield(metadata, "networkVersion") || ...
            string(metadata.networkVersion) ~= string(expectedNetworkVersion)
        error("alphazero:IncompatibleModel", ...
            "Checkpoint %s is not compatible with network version %s.", ...
            string(filePath), string(expectedNetworkVersion));
    end
end
end
