function results = run_elm_pilot()
root=setup_task2; cfg=task2_config(root); if ~exist(cfg.results_dir,'dir'),mkdir(cfg.results_dir);end
D=load(cfg.consolidated_file,'dataset'); F=load(cfg.failure_file,'failure_data');
split=create_realization_split(cfg); save(cfg.split_file,'split'); rows=[];
for p=1:cfg.num_points
 for r=1:cfg.num_responses
  data=prepare_case_dataset(D.dataset,F.failure_data,split,p,r);
  sx=fit_standardizer(data.X_development); sy=fit_standardizer(data.y_development);
  Xd=apply_standardizer(data.X_development,sx); yd=apply_standardizer(data.y_development,sy);
  Xt=apply_standardizer(data.X_test,sx);
  t=tic; model=train_elm(Xd,yd,cfg.elm,cfg.seed+100*p+r); train_s=toc(t);
  t=tic; pred_z=predict_elm(model,Xt); predict_s=toc(t);
  pred=pred_z.*sy.std+sy.mean; m=calculate_regression_metrics(data.y_test,pred);
  rows=[rows; table(p,r,m.n,m.R2,m.nRMSE,m.nMAE,m.a10,m.a10_eligible,m.constant_reference,train_s,predict_s, ...
   'VariableNames',{'point','response','n_test','R2','nRMSE','nMAE','a10','a10_eligible','constant_reference','train_s','predict_s'})]; %#ok<AGROW>
 end
end
results=rows; writetable(results,cfg.metrics_file); save(fullfile(cfg.results_dir,'task2_elm_results.mat'),'results','cfg');
end
