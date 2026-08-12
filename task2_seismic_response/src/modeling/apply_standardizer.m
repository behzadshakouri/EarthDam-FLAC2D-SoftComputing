function z = apply_standardizer(x, scaler)
z = (x - scaler.mean) ./ scaler.std;
end
