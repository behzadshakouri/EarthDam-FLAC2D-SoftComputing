function metrics = calculate_regression_metrics(y, yhat)
y=y(:); yhat=yhat(:); valid=isfinite(y)&isfinite(yhat); y=y(valid); yhat=yhat(valid);
metrics.n = numel(y); metrics.constant_reference = range(y) <= eps(max(1,max(abs(y))));
res=sum((y-yhat).^2); total=sum((y-mean(y)).^2);
if metrics.constant_reference, metrics.R2=nan; else, metrics.R2=1-res/total; end
rmse=sqrt(mean((y-yhat).^2)); mae=mean(abs(y-yhat)); denom=max(y)-min(y);
if denom <= eps(max(1,max(abs(y)))), metrics.nRMSE=nan; metrics.nMAE=nan;
else, metrics.nRMSE=rmse/denom; metrics.nMAE=mae/denom; end
tol=max(1e-12, 0.01*median(abs(y(abs(y)>0)),'omitnan'));
eligible=abs(y)>tol; metrics.a10_eligible=sum(eligible);
if any(eligible), ratio=yhat(eligible)./y(eligible); metrics.a10=mean(ratio>=0.9 & ratio<=1.1);
else, metrics.a10=nan; end
end
