function result = run_task3_production(preparedFile)
%RUN_TASK3_PRODUCTION Prepare, fit, test, and export the Task 3 model.
root = setup_task3(); cfg = task3_config(root);
if ~isfolder(cfg.results_dir), mkdir(cfg.results_dir); end
if ~isfolder(cfg.split_dir), mkdir(cfg.split_dir); end
if nargin<1 || isempty(preparedFile)
    [dataset,qc] = load_and_prepare_task3_data(cfg);
else
    prepared=load(preparedFile,'dataset','qc','cfg');
    assert(isequal(prepared.cfg.features,cfg.features) && ...
        isequal(prepared.cfg.output,cfg.output) && isequal(prepared.cfg.qc,cfg.qc), ...
        'Prepared-data settings differ from the current configuration.');
    dataset=prepared.dataset; qc=prepared.qc;
    validate_task3_dataset(dataset,cfg);
end
export_task3_qc(dataset,qc,cfg);
save(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'),'dataset','qc','cfg');
split = create_task3_split(cfg);
write_split_csv(cfg.split_file,split,cfg.num_realizations);

dev = split.development_ids; test = split.test_ids;
xScaler = fit_task3_standardizer(dataset.X(dev,:),cfg.preprocessing.constant_tolerance);
yScaler = fit_task3_standardizer(dataset.Y(dev,:),cfg.preprocessing.constant_tolerance);
Xdev = apply_task3_standardizer(dataset.X(dev,:),xScaler);
Xtest = apply_task3_standardizer(dataset.X(test,:),xScaler);
Ydev = apply_task3_standardizer(dataset.Y(dev,:),yScaler);

% Constant outputs are predicted by their development mean and excluded
% from the FMRVR target covariance calculation.
modeled = ~yScaler.constant;
selection = select_task3_kernel_width(dataset.X(dev,:),dataset.Y(dev,:),cfg);
tic; model = train_task3_fmrvr(Xdev,Ydev(:,modeled),selection.selected_width,cfg);
trainingSeconds = toc;
tic; predStd = predict_task3_fmrvr(model,Xtest); inferenceSeconds = toc;
predAllStd = zeros(numel(test),cfg.num_outputs); predAllStd(:,modeled) = predStd;
prediction = reverse_task3_standardizer(predAllStd,yScaler);
assert(all(isfinite(prediction(:))),'Task3:NonfinitePrediction','Nonfinite test prediction.');
metrics = calculate_task3_metrics(dataset.Y(test,:),prediction,cfg.preprocessing.constant_tolerance);
export_task3_results(dataset.Y(test,:),prediction,test,metrics,dataset.output_dictionary, ...
    selection,model,trainingSeconds,inferenceSeconds,cfg);
if cfg.production.save_model_mat
    save(fullfile(cfg.results_dir,'task3_fmrvr_model.mat'),'model','xScaler','yScaler', ...
        'selection','split','cfg','modeled','-v7.3');
end
result.metrics = metrics; result.prediction = prediction; result.test_ids = test;
result.selection = selection; result.model = model; result.qc = qc;
fprintf('Task 3 complete: %d development, %d test, %d/%d modeled outputs, %d relevance bases.\n', ...
    numel(dev),numel(test),sum(modeled),cfg.num_outputs,numel(model.used));
end

function write_split_csv(path,split,n)
partition = repmat({'development'},n,1); partition(split.test_ids) = {'test'};
T = table((1:n)',partition,'VariableNames',{'realization_id','partition'});
writetable(T,path);
end
