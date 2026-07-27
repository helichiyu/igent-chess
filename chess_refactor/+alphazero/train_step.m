function [net, optimizer, metrics] = train_step(net, states, targetPolicies, targetValues, legalMasks, optimizer, settings)
%TRAIN_STEP Update the policy-value network with one Adam mini-batch.
if nargin < 6 || isempty(optimizer)
    optimizer = struct("iteration", 0, "trailingAverage", [], ...
        "trailingAverageSquared", []);
end
if nargin < 7 || isempty(settings)
    settings = alphazero.config();
end
if settings.useGPU
    if ~canUseGPU
        error("alphazero:GPUUnavailable", "GPU execution was requested but no supported GPU is available.");
    end
    states = gpuArray(states);
    targetPolicies = gpuArray(targetPolicies);
    targetValues = gpuArray(targetValues);
    legalMasks = gpuArray(legalMasks);
end

optimizer.iteration = optimizer.iteration + 1;
[gradients, loss, policyLoss, valueLoss] = dlfeval(@model_gradients, ...
    net, states, targetPolicies, targetValues, legalMasks);
[net, optimizer.trailingAverage, optimizer.trailingAverageSquared] = adamupdate( ...
    net, gradients, optimizer.trailingAverage, optimizer.trailingAverageSquared, ...
    optimizer.iteration, settings.learningRate);
metrics = struct("loss", gather(extractdata(loss)), ...
    "policyLoss", gather(extractdata(policyLoss)), ...
    "valueLoss", gather(extractdata(valueLoss)));
end

function [gradients, loss, policyLoss, valueLoss] = model_gradients(net, states, targetPolicies, targetValues, legalMasks)
[loss, policyLoss, valueLoss] = alphazero.policy_value_loss( ...
    net, states, targetPolicies, targetValues, legalMasks);
gradients = dlgradient(loss, net.Learnables);
end
