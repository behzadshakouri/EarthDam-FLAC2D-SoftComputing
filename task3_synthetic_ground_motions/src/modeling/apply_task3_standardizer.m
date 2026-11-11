function Z = apply_task3_standardizer(A, scaler)
%APPLY_TASK3_STANDARDIZER Apply a previously fitted standardizer.
Z = bsxfun(@rdivide, bsxfun(@minus,A,scaler.mean), scaler.std);
end
