function summary = run_task1_experiments(D,cfg)
%RUN_TASK1_EXPERIMENTS Execute checkpointed response and FoS experiments.
Y=extract_task1_responses(D.outputs_gp,cfg);
if ~isfolder(cfg.results_dir), mkdir(cfg.results_dir); end
rows={}; orderSeed=cfg.seed;
rng(orderSeed,'twister'); masterOrder=randperm(cfg.num_realizations);
caseNo=0;
for ns=cfg.sample_sizes
    selected=masterOrder(1:ns);
    splitLocal=create_task1_split(ns,cfg.development_fraction,cfg.seed+ns);
    split.development=selected(splitLocal.development);
    split.test=selected(splitLocal.test);
    for p=1:cfg.num_points
        for q=1:cfg.num_responses
            y=Y(:,p,q);
            for m=1:numel(cfg.methods)
                method=cfg.methods{m}; caseNo=caseNo+1;
                out=fullfile(cfg.results_dir,sprintf('%s_n%d_P%d_R%d.mat',method,ns,p,q));
                if cfg.production.resume && isfile(out), S=load(out,'R'); R=S.R;
                else
                    h=cfg.production.response_hidden_neurons.(method);
                    R=fit_task1_case(D.RVs,y,method,h,split,cfg,cfg.seed+caseNo);
                    save(out,'R','-v7.3');
                end
                t=R.test_metrics;
                rows(end+1,:)={method,ns,p,q,t.R2,t.RMSE,t.MAE,t.a10}; %#ok<AGROW>
            end
        end
    end
end
summary=cell2table(rows,'VariableNames', ...
    {'method','sample_size','point','response','R2_test','RMSE_test','MAE_test','a10_test'});
writetable(summary,fullfile(cfg.results_dir,'task1_all_model_metrics.csv'));

if ~isempty(D.fos_y)
    fosRows={}; fosCaseNo=0;
    for ns=cfg.sample_sizes
        selected=masterOrder(1:ns);
        splitLocal=create_task1_split(ns,cfg.development_fraction,cfg.seed+ns);
        split.development=selected(splitLocal.development);
        split.test=selected(splitLocal.test);
        for m=1:numel(cfg.methods)
            method=cfg.methods{m}; fosCaseNo=fosCaseNo+1;
            out=fullfile(cfg.results_dir,sprintf('%s_FoS_n%d.mat',method,ns));
            if cfg.production.resume && isfile(out), S=load(out,'R'); R=S.R;
            else
                h=cfg.production.fos_hidden_neurons.(method);
                R=fit_task1_case(D.fos_X,D.fos_y,method,h,split,cfg, ...
                    cfg.seed+9000+fosCaseNo);
                save(out,'R','-v7.3');
            end
            t=R.test_metrics;
            fosRows(end+1,:)={method,ns,numel(split.development), ...
                numel(split.test),t.R2,t.RMSE,t.MAE,t.a10}; %#ok<AGROW>
        end
    end
    fosSummary=cell2table(fosRows,'VariableNames', ...
        {'method','sample_size','n_train','n_test','R2_test', ...
         'RMSE_test','MAE_test','a10_test'});
    writetable(fosSummary,fullfile(cfg.results_dir,'task1_fos_model_metrics.csv'));
end
end
