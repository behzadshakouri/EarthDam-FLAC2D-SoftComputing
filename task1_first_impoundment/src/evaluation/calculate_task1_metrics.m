function M = calculate_task1_metrics(observed,predicted)
%CALCULATE_TASK1_METRICS Paper metrics for one scalar target.
observed=observed(:); predicted=predicted(:);
assert(numel(observed)==numel(predicted) && all(isfinite([observed;predicted])));
C=corrcoef(observed,predicted);
if numel(C)<4 || ~isfinite(C(1,2)), R2=NaN; else, R2=C(1,2)^2; end
e=predicted-observed;
RMSE=sqrt(mean(e.^2)); MAE=mean(abs(e));
den=max(abs(observed),eps(class(observed)));
a10=mean(abs(e)./den<=0.10);
M=table(R2,RMSE,MAE,a10);
end
