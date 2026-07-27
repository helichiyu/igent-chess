function save_model(net, filePath, metadata)
%SAVE_MODEL Save network weights and experiment metadata.
if nargin < 3
    metadata = struct();
end
filePath = string(filePath);
folder = fileparts(filePath);
if strlength(folder) > 0 && ~isfolder(folder)
    mkdir(folder);
end
save(filePath, "net", "metadata", "-v7.3");
end
