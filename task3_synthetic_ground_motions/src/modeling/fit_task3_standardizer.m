function scaler = fit_task3_standardizer(A, tolerance)
%FIT_TASK3_STANDARDIZER Fit using development data only.
scaler.mean = mean(A,1); scaler.std = std(A,0,1);
scaler.constant = scaler.std <= tolerance | ~isfinite(scaler.std);
scaler.std(scaler.constant) = 1;
end
