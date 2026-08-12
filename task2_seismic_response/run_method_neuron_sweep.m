function summary = run_method_neuron_sweep(methods)
%RUN_METHOD_NEURON_SWEEP Controlled FULL70 neuron sweep for all four methods.
% Plain ELM uses [10 20 30]. The optimized ELM variants use [5 10 15].
% Each method/count combination has an isolated, resumable output directory
% and reuses the existing fixed 210/90 realization split.

if nargin<1||isempty(methods)
 methods={'ELM','ELMABC','ELMACOR','ELMIGWO'};
end
if ischar(methods)||isstring(methods),methods=cellstr(methods);end

allowed={'ELM','ELMABC','ELMACOR','ELMIGWO'};
methods=upper(string(methods(:)'));
if any(~ismember(methods,allowed))
 error('Task2:UnknownMethod','Methods must be ELM, ELMABC, ELMACOR, or ELMIGWO.');
end

root=setup_task2;
cfg=task2_config(root);
assert(exist(cfg.split_file,'file')==2, ...
 'Fixed split is missing. Complete data preparation before this sweep.');

sweep_root=fullfile(root,'results','method_neuron_sweep');
if ~exist(sweep_root,'dir'),mkdir(sweep_root);end
summary_file=fullfile(sweep_root,'method_neuron_sweep_summary.csv');
summary_mat=fullfile(sweep_root,'method_neuron_sweep_summary.mat');
if exist(summary_mat,'file')==2
 saved=load(summary_mat,'summary');
 summary=saved.summary;
else
 summary=table();
end

for method=methods
 if method=="ELM",neuron_counts=[10 20 30];else,neuron_counts=[5 10 15];end
 for n=neuron_counts
  experiment=sprintf('%s_N%03d',char(method),n);
  out_dir=fullfile(sweep_root,experiment);
  override=struct();
  override.make_case_plots=false;
  override.make_summary_plots=false;
  override.resume=true;
  switch method
   case "ELM"
    override.elm=cfg.production.elm;
    override.elm.hidden_neurons=n;
   case "ELMABC"
    override.abc=cfg.production.abc;
    override.abc.hidden_neurons=n;
   case "ELMACOR"
    override.acor=cfg.production.acor;
    override.acor.hidden_neurons=n;
   case "ELMIGWO"
    override.igwo=cfg.production.igwo;
    override.igwo.hidden_neurons=n;
  end

  fprintf('\n============================================================\n');
  fprintf('Starting/resuming FULL70 %s with %d hidden neurons\n',method,n);
  fprintf('Output: %s\n',out_dir);
  fprintf('============================================================\n');
  run_all_models(char(method),[],out_dir,override);

  metrics_file=fullfile(out_dir,sprintf('task2_%s_metrics.csv',lower(char(method))));
  T=readtable(metrics_file);
  modeled=~T.constant_reference & isfinite(T.R2);
  row=table(method,n,height(T),sum(modeled),mean(T.R2(modeled),'omitnan'), ...
   median(T.R2(modeled),'omitnan'),mean(T.nRMSE(modeled),'omitnan'), ...
   mean(T.nMAE(modeled),'omitnan'),mean(T.a10(modeled),'omitnan'), ...
   sum(T.R2(modeled)>=0.90),sum(T.train_s,'omitnan'),string(out_dir), ...
   'VariableNames',{'method','hidden_neurons','case_count','modeled_cases', ...
   'mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10', ...
   'cases_R2_ge_090','total_train_s','results_dir'});
  if ~isempty(summary)
   same=string(summary.method)==method & summary.hidden_neurons==n;
   summary(same,:)=[];
  end
  summary=[summary;row]; %#ok<AGROW>
  summary=sortrows(summary,{'method','hidden_neurons'});
  writetable(summary,summary_file);
  save(summary_mat,'summary','methods','-v7.3');
 end
end

disp(summary);
fprintf('All requested sweeps complete. Summary: %s\n',summary_file);
end
