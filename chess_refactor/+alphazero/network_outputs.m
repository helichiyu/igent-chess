function [policyLogits, value] = network_outputs(net, states)
%NETWORK_OUTPUTS Evaluate policy logits and current-player value estimates.
if ndims(states) == 3
    states = reshape(states, 10, 9, 14, 1);
end
validateattributes(states, {'single', 'double'}, {'size', [10 9 14 NaN]});
raw = forward(net, dlarray(single(states), "SSCB"));
raw = reshape(raw, 8101, []);
policyLogits = raw(1:8100, :);
value = tanh(raw(8101, :));
end
