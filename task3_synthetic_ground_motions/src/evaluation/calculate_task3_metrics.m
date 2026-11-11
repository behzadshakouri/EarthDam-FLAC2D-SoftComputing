function metrics = calculate_task3_metrics(observed, predicted, tolerance)
%CALCULATE_TASK3_METRICS Per-output regression metrics.
if nargin < 3, tolerance = 1e-12; end
assert(isequal(size(observed),size(predicted)));
v = size(observed,2);
metrics = repmat(struct('n',0,'R2',NaN,'RMSE',NaN,'nRMSE',NaN, ...
    'MAE',NaN,'nMAE',NaN,'a10',NaN,'constant',false),v,1);
for j = 1:v
    y = observed(:,j); p = predicted(:,j); valid = isfinite(y)&isfinite(p);
    y = y(valid); p = p(valid); err = p-y; span = max(y)-min(y);
    metrics(j).n = numel(y); metrics(j).RMSE = sqrt(mean(err.^2));
    metrics(j).MAE = mean(abs(err)); metrics(j).constant = span <= tolerance;
    if ~metrics(j).constant
        metrics(j).R2 = 1-sum(err.^2)/sum((y-mean(y)).^2);
        metrics(j).nRMSE = metrics(j).RMSE/span;
        metrics(j).nMAE = metrics(j).MAE/span;
    end
    denom = max(abs(y),tolerance);
    metrics(j).a10 = mean(abs(p-y)./denom <= 0.10);
end
end
