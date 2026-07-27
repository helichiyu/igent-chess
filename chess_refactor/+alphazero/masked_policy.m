function probabilities = masked_policy(policyLogits, legalMask)
%MASKED_POLICY Normalize logits over legal actions only.
if ~isequal(size(policyLogits, 1), 8100)
    error("alphazero:InvalidPolicy", "Policy logits must have 8100 rows.");
end
if isvector(legalMask)
    legalMask = reshape(legalMask, 8100, 1);
end
if ~isequal(size(legalMask), size(policyLogits))
    error("alphazero:InvalidMask", "Legal mask dimensions must match policy logits.");
end
if any(sum(legalMask, 1) == 0)
    error("alphazero:EmptyLegalMask", "Each policy requires at least one legal action.");
end
maskedLogits = policyLogits;
maskedLogits(~logical(legalMask)) = -1e9;
shifted = maskedLogits - max(maskedLogits, [], 1);
unnormalized = exp(shifted) .* legalMask;
probabilities = unnormalized ./ sum(unnormalized, 1);
end
