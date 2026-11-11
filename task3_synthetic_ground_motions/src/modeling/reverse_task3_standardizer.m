function A = reverse_task3_standardizer(Z, scaler)
%REVERSE_TASK3_STANDARDIZER Return standardized values to physical units.
A = bsxfun(@plus, bsxfun(@times,Z,scaler.std), scaler.mean);
end
