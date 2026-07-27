function buffer = load_replay_chunks(directory, capacity)
%LOAD_REPLAY_CHUNKS Restore newest replay chunks up to a fixed capacity.
buffer = alphazero.ReplayBuffer(capacity);
if ~isfolder(directory)
    return;
end
files = dir(fullfile(directory, "replay_*.mat"));
[~, order] = sort({files.name});
files = files(order);
for index = 1:numel(files)
    data = load(fullfile(files(index).folder, files(index).name), "samples");
    buffer.add(data.samples);
end
end
