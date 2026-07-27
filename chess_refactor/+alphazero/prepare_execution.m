function prepare_execution(settings)
%PREPARE_EXECUTION Enable supported GPU compatibility before training.
if ~settings.useGPU
    return;
end
if ~canUseGPU
    % MATLAB R2024b needs this for newer CUDA compute capabilities.
    parallel.gpu.enableCUDAForwardCompatibility(true);
end
if ~canUseGPU
    error("alphazero:GPUUnavailable", ...
        "GPU execution was requested but MATLAB cannot use a supported GPU.");
end
end
