function generate_task2_plots()
%GENERATE_TASK2_PLOTS Regenerate plots from every saved case without retraining.
root=setup_task2;cfg=task2_config(root);rows=table();
methods=cfg.production.models;
for im=1:numel(methods)
 method=upper(string(methods{im}));methodDir=fullfile(cfg.results_dir,char(method));
 if ~exist(methodDir,'dir'),continue;end
 files=dir(fullfile(methodDir,'P*_R*.mat'));
 for k=1:numel(files)
  S=load(fullfile(files(k).folder,files(k).name),'case_result');cr=S.case_result;
  plot_task2_case_result(cr,cfg.results_dir);rows=[rows;cr.metrics]; %#ok<AGROW>
 end
end
if ~isempty(rows),plot_task2_summary(rows,cfg.results_dir);end
fprintf('Plots generated from %d saved model-cases in %s\n',height(rows),fullfile(cfg.results_dir,'plots'));
end
