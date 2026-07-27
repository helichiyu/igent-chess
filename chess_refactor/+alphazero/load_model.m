function [net, metadata] = load_model(filePath)
%LOAD_MODEL Load a policy-value network and its experiment metadata.
data = load(filePath, "net", "metadata");
net = data.net;
if isfield(data, "metadata")
    metadata = data.metadata;
else
    metadata = struct();
end
end
