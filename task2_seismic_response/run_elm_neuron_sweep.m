function summary = run_elm_neuron_sweep(neuron_counts)
%RUN_ELM_NEURON_SWEEP Run isolated FULL70 plain-ELM neuron experiments.
% Default new sizes: 25, 40, 50, and 60. The validated 20- and 30-neuron
% results are intentionally not rerun. Every size uses the existing fixed
% 210/90 realization split and receives a separate results directory.

if nargin<1||isempty(neuron_counts),neuron_counts=[25 40 50 60];end
validateattributes(neuron_counts,{'numeric'},{'vector','integer','positive','finite'});
neuron_counts=unique(neuron_counts(:)','stable');

root=setup_task2;
cfg=task2_config(root);
assert(exist(cfg.split_file,'file')==2, ...
 'Fixed split is missing. Complete data preparation before this sweep.');

sweep_root=fullfile(root,'results','elm_neuron_sweep');
if ~exist(sweep_root,'dir'),mkdir(sweep_root);end
summary=table();

for n=neuron_counts
 out_dir=fullfile(sweep_root,sprintf('ELM_N%03d',n));
 override=struct();
 override.elm=cfg.production.elm;
 override.elm.hidden_neurons=n;
 override.make_case_plots=false;
 override.make_summary_plots=false;
 override.resume=true;

 fprintf('\n============================================================\n');
 fprintf('Starting/resuming FULL70 ELM with %d hidden neurons\n',n);
 fprintf('Output: %s\n',out_dir);
 fprintf('============================================================\n');
 run_all_models('ELM',[],out_dir,override);

 T=readtable(fullfile(out_dir,'task2_elm_metrics.csv'));
 modeled=~T.constant_reference & isfinite(T.R2);
 row=table(n,height(T),sum(modeled),mean(T.R2(modeled),'omitnan'), ...
  median(T.R2(modeled),'omitnan'),mean(T.nRMSE(modeled),'omitnan'), ...
  mean(T.nMAE(modeled),'omitnan'),mean(T.a10(modeled),'omitnan'), ...
  sum(T.R2(modeled)>=0.90),sum(T.train_s,'omitnan'),string(out_dir), ...
  'VariableNames',{'hidden_neurons','case_count','modeled_cases','mean_R2', ...
  'median_R2','mean_nRMSE','mean_nMAE','mean_a10','cases_R2_ge_090', ...
  'total_train_s','results_dir'});
 summary=[summary;row]; %#ok<AGROW>
 writetable(summary,fullfile(sweep_root,'elm_neuron_sweep_summary.csv'));
 save(fullfile(sweep_root,'elm_neuron_sweep_summary.mat'),'summary','neuron_counts','-v7.3');
end

summary=sortrows(summary,'hidden_neurons');
disp(summary);
fprintf('Sweep complete. Summary: %s\n', ...
 fullfile(sweep_root,'elm_neuron_sweep_summary.csv'));
end
