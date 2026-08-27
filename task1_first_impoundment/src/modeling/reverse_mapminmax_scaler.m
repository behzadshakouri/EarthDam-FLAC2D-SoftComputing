function X = reverse_mapminmax_scaler(Z,settings)
%REVERSE_MAPMINMAX_SCALER Reverse development-fitted FULL70 scaling.
X = mapminmax('reverse',double(Z)',settings)';
end
