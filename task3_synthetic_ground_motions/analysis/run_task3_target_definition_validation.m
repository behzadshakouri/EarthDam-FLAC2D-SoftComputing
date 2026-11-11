function report=run_task3_target_definition_validation()
%RUN_TASK3_TARGET_DEFINITION_VALIDATION Leakage-safe target-definition audit.
% Compares scalar response definitions on identical stratified outer splits.
% Model selection (ridge penalty) uses only each outer development subset.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root);
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3');
[X,~,groups]=build_task3_augmented_features(raw.Task3,cfg); X=X(:,groups.spectral);
[Ycurrent,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
Ytotal=common_onset_targets(raw.Task3,prepared.dataset,audit,cfg,"total");
Yincrement=common_onset_targets(raw.Task3,prepared.dataset,audit,cfg,"increment");
responseSpecific=load(fullfile(resultsDir,'task3_response_specific_envelope_targets.mat'),'Y');

names=["current_hybrid_common_onset";"total_response_common_onset"; ...
    "increment_from_initial_common_onset";"current_hybrid_response_specific_onset"];
targets={Ycurrent,Ytotal,Yincrement,responseSpecific.Y};
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
lambdas=[.01 .1 1 10 100]; outer=table; perOutput=table;
dictionary=prepared.dataset.output_dictionary;

for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    folds=stratified_folds(failure(dev),3,cfg.seed+7100+repeat);
    for definition=1:numel(targets)
        Y=targets{definition}; scores=nan(numel(lambdas),1);
        for candidate=1:numel(lambdas)
            prediction=nan(numel(dev),size(Y,2));
            for fold=1:3
                tr=dev(folds~=fold); va=dev(folds==fold);
                model=fit_ridge(X(tr,:),Y(tr,:),lambdas(candidate),cfg);
                prediction(folds==fold,:)=predict_ridge(model,X(va,:));
            end
            metrics=calculate_task3_metrics(Y(dev,:),prediction,cfg.preprocessing.constant_tolerance);
            use=~[metrics.constant]; scores(candidate)=mean([metrics(use).nRMSE]);
        end
        [innerScore,best]=min(scores); lambda=lambdas(best);
        model=fit_ridge(X(dev,:),Y(dev,:),lambda,cfg);
        prediction=predict_ridge(model,X(test,:));
        metrics=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance);
        use=~[metrics.constant];
        outer=[outer;table(repeat,names(definition),lambda,innerScore, ...
            mean([metrics(use).R2]),median([metrics(use).R2]),mean([metrics(use).nRMSE]), ...
            mean([metrics(use).nMAE]),sum([metrics(use).R2]>=.7),sum([metrics(use).R2]>=.8), ...
            sum([metrics(use).R2]>=.9),'VariableNames',{'repeat','target_definition', ...
            'selected_lambda','inner_nRMSE','mean_R2','median_R2','mean_nRMSE', ...
            'mean_nMAE','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'})]; %#ok<AGROW>
        perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1), ...
            repmat(names(definition),cfg.num_outputs,1),(1:cfg.num_outputs)', ...
            string({dictionary.label})',[dictionary.response]',[metrics.R2]',[metrics.constant]', ...
            'VariableNames',{'repeat','target_definition','output_column','label', ...
            'response','R2','constant'})]; %#ok<AGROW>
    end
    fprintf('Target-definition validation %d/10 complete.\n',repeat);
end

summary=table;
for definition=1:numel(names)
    rows=outer(outer.target_definition==names(definition),:);
    summary=[summary;table(names(definition),mean(rows.mean_R2),std(rows.mean_R2), ...
        min(rows.mean_R2),max(rows.mean_R2),mean(rows.median_R2), ...
        mean(rows.mean_nRMSE),mean(rows.mean_nMAE),mean(rows.outputs_R2_ge_07), ...
        mean(rows.outputs_R2_ge_08),mean(rows.outputs_R2_ge_09), ...
        'VariableNames',{'target_definition','mean_R2','sd_R2','minimum_R2','maximum_R2', ...
        'mean_median_R2','mean_nRMSE','mean_nMAE','mean_outputs_R2_ge_07', ...
        'mean_outputs_R2_ge_08','mean_outputs_R2_ge_09'})]; %#ok<AGROW>
end
family=table;
for definition=1:numel(names)
    for response=1:7
        rows=perOutput(perOutput.target_definition==names(definition) & ...
            perOutput.response==response & ~perOutput.constant,:);
        family=[family;table(names(definition),response,mean(rows.R2),std(rows.R2), ...
            'VariableNames',{'target_definition','response','mean_R2','sd_R2'})]; %#ok<AGROW>
    end
end
writetable(outer,fullfile(resultsDir,'target_definition_repeated_metrics.csv'));
writetable(perOutput,fullfile(resultsDir,'target_definition_repeated_per_output.csv'));
writetable(summary,fullfile(resultsDir,'target_definition_repeated_summary.csv'));
writetable(family,fullfile(resultsDir,'target_definition_repeated_family_summary.csv'));
report=struct('metrics',outer,'summary',summary,'family',family,'per_output',perOutput);
disp(summary);
end

function Y=common_onset_targets(Task3,dataset,audit,cfg,mode)
dictionary=dataset.output_dictionary; Y=nan(cfg.num_realizations,cfg.num_outputs);
for i=1:cfg.num_realizations
    time=double(Task3.Outputs.dytime{i}(:));
    for k=1:cfg.num_outputs
        p=dictionary(k).point; r=dictionary(k).response;
        history=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){i}(:));
        admissible=isfinite(history) & abs(history)<cfg.qc.sentinel_abs_threshold;
        if isfinite(audit.screening_onset_s(i)), admissible=admissible & time<audit.screening_onset_s(i); end
        values=history(admissible); assert(numel(values)>=cfg.qc.minimum_history_length);
        if mode=="total", Y(i,k)=max(abs(values));
        else, Y(i,k)=max(abs(values-values(1))); end
    end
end
assert(all(isfinite(Y(:))) && all(Y(:)>=0));
end

function model=fit_ridge(X,Y,lambda,cfg)
model.scale=median(abs(X),1); model.scale(model.scale<=eps)=1;
X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);
model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs); Y=apply_task3_standardizer(Y,model.ys);
A=[ones(size(X,1),1) X]; penalty=eye(size(A,2)); penalty(1,1)=0;
model.beta=(A'*A+lambda*penalty)\(A'*Y);
end

function Y=predict_ridge(model,X)
X=asinh(bsxfun(@rdivide,X,model.scale));
X=apply_task3_standardizer(X,model.xs);
Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister'); fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value); ids=ids(randperm(numel(ids)));
    for j=1:numel(ids), fold(ids(j))=mod(j-1,k)+1; end
end
end
