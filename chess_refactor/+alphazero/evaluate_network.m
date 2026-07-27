function [policy, value] = evaluate_network(net, state, useGPU)
%EVALUATE_NETWORK Return legal action priors and value for one search state.
if nargin < 3 || isempty(useGPU)
    settings = alphazero.config();
    useGPU = settings.useGPU;
end
encoded = alphazero.encode_state(state);
mask = alphazero.legal_action_mask(state);
if useGPU && canUseGPU
    encoded = gpuArray(encoded);
end
[logits, value] = alphazero.network_outputs(net, encoded);
policy = alphazero.masked_policy(extractdata(logits), mask);
policy = gather(policy);
value = gather(extractdata(value));
end
