function scaler = fit_standardizer(x)
scaler.mean = mean(x,1,'omitnan'); scaler.std = std(x,0,1,'omitnan');
scaler.std(~isfinite(scaler.std) | scaler.std < eps) = 1;
end
