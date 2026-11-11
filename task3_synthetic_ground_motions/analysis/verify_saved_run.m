function verify_saved_run()
%VERIFY_SAVED_RUN Confirm that the saved production model reproduces exports.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);
addpath(root);setup_task3;cfg=task3_config(root);
s=load(fullfile(cfg.results_dir,'task3_fmrvr_model.mat'));
d=load(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'));
ids=s.split.test_ids;
p=zeros(numel(ids),70);
p(:,s.modeled)=predict_task3_fmrvr(s.model,apply_task3_standardizer(d.dataset.X(ids,:),s.xScaler));
p=reverse_task3_standardizer(p,s.yScaler);
T=readtable(fullfile(cfg.results_dir,'task3_test_predictions.csv'));
old=table2array(T(:,3:2:141));
assert(all(abs(p(:)-old(:))<=1e-12*max(1,abs(p(:)))));
metrics=calculate_task3_metrics(d.dataset.Y(ids,:),p,1e-12);
summary=readtable('results/final_production/task3_run_summary.csv');
export_task3_results(d.dataset.Y(ids,:),p,ids,metrics,d.dataset.output_dictionary,s.selection,s.model,summary.training_seconds,summary.test_inference_seconds,s.cfg);
fprintf('Saved Task 3 model reproduces all 3150 exported test predictions. Rank=%d; iterations=%d.\n',s.model.output_rank,s.model.iterations);
end
