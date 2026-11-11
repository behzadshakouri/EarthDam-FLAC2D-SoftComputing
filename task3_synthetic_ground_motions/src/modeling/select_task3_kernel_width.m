function selection = select_task3_kernel_width(X, Y, cfg)
%SELECT_TASK3_KERNEL_WIDTH Select a width factor using fold-local preprocessing.
n=size(X,1); k=cfg.fmrvr.cv_folds; rng(cfg.seed+1,'twister');
assert(k>=2 && k<=n,'Invalid cross-validation fold count.');
foldOrder=randperm(n); fold=zeros(n,1);
for i=1:n, fold(foldOrder(i))=mod(i-1,k)+1; end
factors=cfg.fmrvr.kernel_width_factors;
scores=nan(numel(factors),k); foldWidths=zeros(numel(factors),k);
for f=1:k
    train=fold~=f; valid=fold==f;
    xs=fit_task3_standardizer(X(train,:),cfg.preprocessing.constant_tolerance);
    ys=fit_task3_standardizer(Y(train,:),cfg.preprocessing.constant_tolerance);
    xt=apply_task3_standardizer(X(train,:),xs);
    xv=apply_task3_standardizer(X(valid,:),xs);
    yt=apply_task3_standardizer(Y(train,:),ys);
    modeled=~ys.constant;
    base=task3_median_distance(xt);
    for w=1:numel(factors)
        foldWidths(w,f)=base*factors(w);
        predStd=zeros(sum(valid),size(Y,2));
        if any(modeled)
            model=train_task3_fmrvr(xt,yt(:,modeled),foldWidths(w,f),cfg);
            predStd(:,modeled)=predict_task3_fmrvr(model,xv);
        end
        pred=reverse_task3_standardizer(predStd,ys);
        assert(all(isfinite(pred(:))),'Task3:NonfinitePrediction','Nonfinite CV prediction.');
        m=calculate_task3_metrics(Y(valid,:),pred,cfg.preprocessing.constant_tolerance);
        usable=~[m.constant];
        assert(any(usable),'Task3:ConstantValidation','No variable validation outputs in fold.');
        scores(w,f)=mean([m(usable).nRMSE]);
        fprintf('Task 3 CV fold %d/%d, factor %.3g: mean nRMSE %.6g.\n',f,k,factors(w),scores(w,f));
    end
end
assert(all(isfinite(scores(:))),'Task3:InvalidCV','CV scores must be finite.');
meanScore=mean(scores,2); [~,best]=min(meanScore);
% Final width is expressed in the full-development standardized coordinates.
xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
baseWidth=task3_median_distance(apply_task3_standardizer(X,xs));
selection.base_width=baseWidth; selection.widths=baseWidth*factors;
selection.width_factors=factors; selection.fold_widths=foldWidths;
selection.fold_scores=scores; selection.mean_scores=meanScore;
selection.selected_width=selection.widths(best); selection.selected_index=best;
selection.fold_assignment=fold;
end
