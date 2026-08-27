function Z = apply_mapminmax_scaler(X,settings)
%APPLY_MAPMINMAX_SCALER Apply development-fitted FULL70 scaling.
Z = mapminmax('apply',double(X)',settings)';
end
