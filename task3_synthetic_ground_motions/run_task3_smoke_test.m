function run_task3_smoke_test()
%RUN_TASK3_SMOKE_TEST Public-data-free end-to-end structural validation.
root = setup_task3(); cfg = task3_config(root);
cfg.num_realizations = 30; cfg.development_count = 21; cfg.test_count = 9;
cfg.num_points = 2; cfg.num_responses = 3; cfg.num_outputs = 6;
cfg.output.reduction_modes = cfg.output.reduction_modes(1:3);
cfg.fmrvr.cv_folds = 3; cfg.fmrvr.kernel_width_factors = [0.5 1.0];
cfg.fmrvr.max_iterations = 150;
rng(11,'twister'); X = randn(30,4);
Y = [sin(X(:,1))+0.05*randn(30,1), X(:,1).*X(:,2), X(:,3).^2, ...
    X(:,1)+X(:,4), cos(X(:,2)), 0.5*X(:,1)-X(:,3)];
split = create_task3_split(cfg); dev=split.development_ids; test=split.test_ids;
xScaler=fit_task3_standardizer(X(dev,:),cfg.preprocessing.constant_tolerance);
yScaler=fit_task3_standardizer(Y(dev,:),cfg.preprocessing.constant_tolerance);
Xdev=apply_task3_standardizer(X(dev,:),xScaler);
Ydev=apply_task3_standardizer(Y(dev,:),yScaler);
selection=select_task3_kernel_width(Xdev,Ydev,cfg);
model=train_task3_fmrvr(Xdev,Ydev,selection.selected_width,cfg);
pred=predict_task3_fmrvr(model,apply_task3_standardizer(X(test,:),xScaler));
pred=reverse_task3_standardizer(pred,yScaler);
assert(isequal(size(pred),[9 6]) && all(isfinite(pred(:))));
dependent=[Ydev Ydev(:,1)+2*Ydev(:,2)];
rankModel=train_task3_fmrvr(Xdev,dependent,selection.selected_width,cfg);
rankPred=predict_task3_fmrvr(rankModel,Xdev);
assert(rankModel.output_rank==6);
assert(max(abs(rankPred(:,7)-rankPred(:,1)-2*rankPred(:,2)))<1e-8);
% With no informative basis, the source solver may select an empty model.
emptyTargets=[(-5:5)' ((-5:5)'.^2)];
emptyTargets=bsxfun(@minus,emptyTargets,mean(emptyTargets,1));
[used,~,mu,precision]=fmrvr_task3(ones(11,12),emptyTargets,10,0.1);
assert(isempty(used) && isequal(size(mu),[0 2]) && isempty(precision));
[cleaned,info]=clean_task3_history([1 2 -1e35 4],cfg);
assert(isequal(cleaned,[1;2]) && info.was_truncated);
assert(reduce_task3_history([-1 2 -4],'max_absolute')==4);
fprintf('Task 3 synthetic smoke test passed: 30 samples, 6 outputs.\n');
end
