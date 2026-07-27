function filePath = save_replay_chunk(samples, directory, chunkIndex)
%SAVE_REPLAY_CHUNK Persist one bounded self-play batch as a MAT-file chunk.
if ~isfolder(directory)
    mkdir(directory);
end
filePath = fullfile(directory, sprintf("replay_%06d.mat", chunkIndex));
save(filePath, "samples", "-v7.3");
end
