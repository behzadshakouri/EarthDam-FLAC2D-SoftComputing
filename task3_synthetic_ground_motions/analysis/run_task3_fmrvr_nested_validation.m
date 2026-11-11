function report=run_task3_fmrvr_nested_validation()
%RUN_TASK3_FMRVR_NESTED_VALIDATION Nested repeated validation of improved FMRVR.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg); X=X(:,groups.spectral);
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
audit=readtable(fullfile(resultsDir,'instability_screening_audit.csv'));
failed=find(logical(audit.had_sentinel)); stable=find(~logical(audit.had_sentinel));

specs=repmat(make_spec(0,Inf),0,1); id=0;
for mix=[.1 .25 .5 .75 .9]
    id=id+1; specs(id)=make_spec(mix,Inf); %#ok<AGROW>
end
for mix=[.25 .5 .75 .9]
    id=id+1; specs(id)=make_spec(mix,5); %#ok<AGROW>
end
nRepeats=10; outer=table; selections=table;
for repeat=1:nRepeats
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=make_folds(numel(dev),3,cfg.seed+1600+repeat); score=nan(numel(specs),1);
    for c=1:numel(specs)
        pred=nan(numel(dev),size(Y,2));
        for f=1:3
            tr=dev(fold~=f); va=dev(fold==f);
            model=fit_task3_fmrvr_variant(X(tr,:),Y(tr,:),specs(c),cfg);
            pred(fold==f,:)=predict_task3_fmrvr_variant(model,X(va,:));
        end
        mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        score(c)=mean([mt(use).nRMSE]);
    end
    [~,best]=min(score); model=fit_task3_fmrvr_variant(X(dev,:),Y(dev,:),specs(best),cfg);
    pred=predict_task3_fmrvr_variant(model,X(test,:)); mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    outer=[outer;table(repeat,mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]), ...
        mean([mt(use).nMAE]),mean([mt(use).a10]),model.used_total, ...
        'VariableNames',{'repeat','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','relevance_basis_count'})]; %#ok<AGROW>
    selections=[selections;table(repeat,best,specs(best).linear_mix,specs(best).output_rank,score(best), ...
        'VariableNames',{'repeat','candidate_id','linear_mix','output_rank','inner_nRMSE'})]; %#ok<AGROW>
    fprintf('Nested improved FMRVR repeat %d/%d: R2 %.4f, mix %.2f, rank %.0f.\n',repeat,nRepeats,outer.mean_R2(end),specs(best).linear_mix,specs(best).output_rank);
end
summary=table(mean(outer.mean_R2),std(outer.mean_R2),min(outer.mean_R2),max(outer.mean_R2),median(outer.mean_R2), ...
    mean(outer.mean_nRMSE),mean(outer.mean_nMAE),mean(outer.mean_a10), ...
    'VariableNames',{'mean_R2','sd_R2','minimum_R2','maximum_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'});
writetable(outer,fullfile(resultsDir,'fmrvr_improved_nested_metrics.csv'));
writetable(selections,fullfile(resultsDir,'fmrvr_improved_nested_selections.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_improved_nested_summary.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 760 460]);
scatter(outer.repeat,outer.mean_R2,55,'filled'); hold on; yline(mean(outer.mean_R2),'--'); yline(.7,':'); grid on;
xlabel('Outer split'); ylabel('Mean held-out R^2'); title('Nested validation of improved FMRVR'); set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_improved_nested_validation.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_improved_nested_validation.png'),'-dpng','-r220'); close(f);
report.summary=summary; report.metrics=outer; report.selections=selections;
end
function spec=make_spec(mix,rank)
spec.input_asinh=true; spec.distance='supervised'; spec.output_rank=rank; spec.width_factor=.5; spec.linear_mix=mix;
end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
