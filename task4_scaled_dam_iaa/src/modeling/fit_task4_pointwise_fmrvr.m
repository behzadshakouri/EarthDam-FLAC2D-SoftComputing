function model=fit_task4_pointwise_fmrvr(X,Y,options)
%FIT_TASK4_POINTWISE_FMRVR Fit one seven-output response-extraction-point model.
% This canonical entry point preserves the validated implementation while
% avoiding the legacy "peak" name used during early development.
model=fit_task4_fmrvr_peak(X,Y,options);
end
