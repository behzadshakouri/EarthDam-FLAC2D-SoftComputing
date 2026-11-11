function [prediction, predictiveStd] = predict_task3_fmrvr(model, X)
%PREDICT_TASK3_FMRVR Predict joint outputs and optional marginal uncertainty.
assert(strcmp(model.kernel_type,'+gauss'));
Phi = task3_rbf_design(X, model.centers, model.width, true);
PhiUsed = Phi(:,model.used); prediction = PhiUsed * model.Mu;
if isfield(model,'output_mean'), prediction=bsxfun(@plus,prediction,model.output_mean); end
if nargout > 1
    leverage = diag(PhiUsed * (model.invSigma\PhiUsed'));
    variance = bsxfun(@times, 1 + leverage, diag(model.Omega)');
    predictiveStd = sqrt(max(variance,0));
end
end
