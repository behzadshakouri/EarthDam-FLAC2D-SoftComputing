function [Z,settings] = fit_mapminmax_scaler(X)
%FIT_MAPMINMAX_SCALER Fit the same [-1,1] transformation used by FULL70.
% Rows are observations and columns are variables.
[zt,settings] = mapminmax(double(X)');
Z = zt';
end
