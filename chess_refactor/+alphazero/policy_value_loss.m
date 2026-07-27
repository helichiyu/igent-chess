function [loss, policyLoss, valueLoss] = policy_value_loss(net, states, targetPolicies, targetValues, legalMasks)
%POLICY_VALUE_LOSS Compute masked policy cross-entropy plus value MSE.
[logits, predictedValues] = alphazero.network_outputs(net, states);
if ~isequal(size(targetPolicies), size(logits)) || ~isequal(size(legalMasks), size(logits))
    error("alphazero:InvalidTargets", "Policy targets and masks must match network policy output.");
end
maskedLogits = logits;
maskedLogits(~logical(legalMasks)) = -1e9;
logProbabilities = maskedLogits - log(sum(exp(maskedLogits), 1));
policyLoss = -mean(sum(targetPolicies .* logProbabilities, 1));
valueLoss = mean((predictedValues - targetValues) .^ 2);
loss = policyLoss + valueLoss;
end
