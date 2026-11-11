function report=run_task3_fmrvr_severity_family_validation()
%RUN_TASK3_FMRVR_SEVERITY_FAMILY_VALIDATION Nested severity/family refinement.
% Failure probability and normalized time remaining after onset are predicted
% from development data only. Family-specific choices are made from inner OOF
% predictions and evaluated once on each matched outer test subset.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
cfg.fmrvr.max_iterations=400; cfg.fmrvr.tolerance=.2;
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,~,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); [Y,audit]=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
failure=logical(audit.had_sentinel); failed=find(failure); stable=find(~failure);
duration=zeros(cfg.num_realizations,1);
for i=1:cfg.num_realizations
    time=double(raw.Task3.Outputs.dytime{i}(:)); duration(i)=time(end)-time(1);
end
severity=zeros(cfg.num_realizations,1);
severity(failure)=max(0,min(1,(duration(failure)-audit.screening_onset_s(failure))./duration(failure)));
assert(all(isfinite(severity)) && all(severity>=0 & severity<=1));

spec.width_factors=[.5 1 2]; spec.linear_mix=.5; spec.target_transform="none"; spec.output_rank=5;
weakFamilies=[2 4 7]; familyRanks=[2 3]; betaGrid=[0 .25 .5 .75 1]; alphaGrid=0:.1:1;
outer=table; selections=table; perOutput=table; dictionary=prepared.dataset.output_dictionary;
for repeat=1:10
    rng(cfg.seed+1500+repeat,'twister'); a=failed(randperm(numel(failed))); b=stable(randperm(numel(stable)));
    dev=sort([a(1:34);b(1:71)]); test=sort([a(35:end);b(72:end)]);
    fold=stratified_folds(failure(dev),3,cfg.seed+2400+repeat);
    globalOof=nan(numel(dev),cfg.num_outputs); stableOof=globalOof; unstableOof=globalOof;
    probabilityOof=nan(numel(dev),1); severityOof=probabilityOof;
    familyOof=cell(7,numel(familyRanks));
    for response=weakFamilies
        ids=response:7:cfg.num_outputs;
        for q=1:numel(familyRanks),familyOof{response,q}=nan(numel(dev),numel(ids));end
    end
    for f=1:3
        tr=dev(fold~=f); va=dev(fold==f); vaRows=fold==f;
        gm=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,:),spec,cfg);
        sm=fit_task3_fmrvr_advanced(X(tr(~failure(tr)),:),Y(tr(~failure(tr)),:),spec,cfg);
        um=fit_task3_fmrvr_advanced(X(tr(failure(tr)),:),Y(tr(failure(tr)),:),spec,cfg);
        globalOof(vaRows,:)=predict_task3_fmrvr_advanced(gm,X(va,:));
        stableOof(vaRows,:)=predict_task3_fmrvr_advanced(sm,X(va,:));
        unstableOof(vaRows,:)=predict_task3_fmrvr_advanced(um,X(va,:));
        [probabilityOof(vaRows),severityOof(vaRows)]=predict_auxiliary( ...
            X(tr,:),X(va,:),failure(tr),severity(tr),cfg);
        for response=weakFamilies
            ids=response:7:cfg.num_outputs;
            for q=1:numel(familyRanks)
                fspec=spec; fspec.output_rank=familyRanks(q);
                fm=fit_task3_fmrvr_advanced(X(tr,:),Y(tr,ids),fspec,cfg);
                familyOof{response,q}(vaRows,:)=predict_task3_fmrvr_advanced(fm,X(va,:));
            end
        end
    end

    % Matched baseline: one development-selected blend using the binary gate.
    baselineScores=nan(numel(alphaGrid),1);
    binaryExpert=bsxfun(@times,1-probabilityOof,stableOof)+bsxfun(@times,probabilityOof,unstableOof);
    for j=1:numel(alphaGrid)
        pred=alphaGrid(j)*globalOof+(1-alphaGrid(j))*binaryExpert;
        mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
        baselineScores(j)=mean([mt(use).nRMSE]);
    end
    [~,j]=min(baselineScores); baselineAlpha=alphaGrid(j);

    % Select gate, global blend, family rank, and family blend inside dev.
    familyChoice=table;
    for response=1:7
        ids=response:7:cfg.num_outputs; gates=make_gates(probabilityOof,severityOof);
        bestScore=inf; bestGate=1; bestAlpha=0; bestRank=0; bestBeta=0;
        for gateId=1:size(gates,2)
            gate=gates(:,gateId);
            expert=bsxfun(@times,1-gate,stableOof(:,ids))+bsxfun(@times,gate,unstableOof(:,ids));
            for alpha=alphaGrid
                base=alpha*globalOof(:,ids)+(1-alpha)*expert;
                candidates={base}; ranks=0; betas=0;
                if ismember(response,weakFamilies)
                    for q=1:numel(familyRanks)
                        for beta=betaGrid
                            candidates{end+1}=(1-beta)*base+beta*familyOof{response,q}; %#ok<AGROW>
                            ranks(end+1)=familyRanks(q); betas(end+1)=beta; %#ok<AGROW>
                        end
                    end
                end
                for c=1:numel(candidates)
                    mt=calculate_task3_metrics(Y(dev,ids),candidates{c},cfg.preprocessing.constant_tolerance);
                    use=~[mt.constant]; score=mean([mt(use).nRMSE]);
                    if score<bestScore
                        bestScore=score;bestGate=gateId;bestAlpha=alpha;bestRank=ranks(c);bestBeta=betas(c);
                    end
                end
            end
        end
        names=gate_names();
        familyChoice=[familyChoice;table(response,names(bestGate),bestGate,bestAlpha,bestRank,bestBeta,bestScore, ...
            'VariableNames',{'response','gate','gate_id','global_weight','family_rank','family_weight','inner_nRMSE'})]; %#ok<AGROW>
        selections=[selections;table(repeat,response,string(dictionary(response).name),names(bestGate), ...
            bestAlpha,bestRank,bestBeta,bestScore,'VariableNames',{'repeat','response','response_name', ...
            'gate','global_weight','family_rank','family_weight','inner_nRMSE'})]; %#ok<AGROW>
    end

    gm=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,:),spec,cfg);
    sm=fit_task3_fmrvr_advanced(X(dev(~failure(dev)),:),Y(dev(~failure(dev)),:),spec,cfg);
    um=fit_task3_fmrvr_advanced(X(dev(failure(dev)),:),Y(dev(failure(dev)),:),spec,cfg);
    pg=predict_task3_fmrvr_advanced(gm,X(test,:));
    ps=predict_task3_fmrvr_advanced(sm,X(test,:)); pu=predict_task3_fmrvr_advanced(um,X(test,:));
    [probability,severityPrediction]=predict_auxiliary(X(dev,:),X(test,:),failure(dev),severity(dev),cfg);
    binaryExpert=bsxfun(@times,1-probability,ps)+bsxfun(@times,probability,pu);
    baselinePrediction=baselineAlpha*pg+(1-baselineAlpha)*binaryExpert;
    structuredPrediction=zeros(size(baselinePrediction)); gates=make_gates(probability,severityPrediction);
    familyModels=cell(7,1);
    for response=weakFamilies
        choice=familyChoice(familyChoice.response==response,:);
        if choice.family_weight>0
            ids=response:7:cfg.num_outputs; fspec=spec; fspec.output_rank=choice.family_rank;
            familyModels{response}=fit_task3_fmrvr_advanced(X(dev,:),Y(dev,ids),fspec,cfg);
        end
    end
    for response=1:7
        ids=response:7:cfg.num_outputs; choice=familyChoice(familyChoice.response==response,:);
        gate=gates(:,choice.gate_id);
        expert=bsxfun(@times,1-gate,ps(:,ids))+bsxfun(@times,gate,pu(:,ids));
        base=choice.global_weight*pg(:,ids)+(1-choice.global_weight)*expert;
        if choice.family_weight>0
            familyPrediction=predict_task3_fmrvr_advanced(familyModels{response},X(test,:));
            base=(1-choice.family_weight)*base+choice.family_weight*familyPrediction;
        end
        structuredPrediction(:,ids)=base;
    end
    baselineMetrics=calculate_task3_metrics(Y(test,:),baselinePrediction,cfg.preprocessing.constant_tolerance);
    structuredMetrics=calculate_task3_metrics(Y(test,:),structuredPrediction,cfg.preprocessing.constant_tolerance);
    use=~[structuredMetrics.constant]; allSeverity=probability.*severityPrediction;
    outer=[outer;table(repeat,mean([baselineMetrics(use).R2]),mean([structuredMetrics(use).R2]), ...
        median([structuredMetrics(use).R2]),mean([structuredMetrics(use).nRMSE]), ...
        mean([structuredMetrics(use).nMAE]),mean([structuredMetrics(use).a10]), ...
        mean((probability>=.5)==failure(test)),sqrt(mean((allSeverity-severity(test)).^2)),baselineAlpha, ...
        'VariableNames',{'repeat','baseline_mean_R2','structured_mean_R2','structured_median_R2', ...
        'structured_mean_nRMSE','structured_mean_nMAE','structured_mean_a10', ...
        'instability_accuracy','severity_RMSE','baseline_global_weight'})]; %#ok<AGROW>
    perOutput=[perOutput;table(repmat(repeat,cfg.num_outputs,1),(1:cfg.num_outputs)', ...
        string({dictionary.label})',[dictionary.point]',[dictionary.response]',string({dictionary.name})', ...
        [baselineMetrics.R2]',[structuredMetrics.R2]',[structuredMetrics.R2]'-[baselineMetrics.R2]', ...
        [structuredMetrics.nRMSE]',[structuredMetrics.constant]', ...
        'VariableNames',{'repeat','output_column','label','point','response','response_name', ...
        'baseline_R2','structured_R2','delta_R2','structured_nRMSE','constant'})]; %#ok<AGROW>
    fprintf('Severity/family FMRVR %d/10: baseline %.4f, structured %.4f, delta %+.4f.\n', ...
        repeat,outer.baseline_mean_R2(end),outer.structured_mean_R2(end), ...
        outer.structured_mean_R2(end)-outer.baseline_mean_R2(end));
end

summary=table(mean(outer.baseline_mean_R2),std(outer.baseline_mean_R2), ...
    mean(outer.structured_mean_R2),std(outer.structured_mean_R2), ...
    min(outer.structured_mean_R2),max(outer.structured_mean_R2), ...
    mean(outer.structured_mean_R2-outer.baseline_mean_R2), ...
    sum(outer.structured_mean_R2>outer.baseline_mean_R2), ...
    mean(outer.structured_mean_nRMSE),mean(outer.structured_mean_nMAE), ...
    mean(outer.structured_mean_a10),mean(outer.instability_accuracy),mean(outer.severity_RMSE), ...
    'VariableNames',{'baseline_mean_R2','baseline_sd_R2','structured_mean_R2','structured_sd_R2', ...
    'structured_minimum_R2','structured_maximum_R2','mean_delta_R2','structured_wins', ...
    'structured_mean_nRMSE','structured_mean_nMAE','structured_mean_a10', ...
    'mean_instability_accuracy','mean_severity_RMSE'});
familySummary=summarize_families(perOutput,dictionary);
writetable(outer,fullfile(resultsDir,'fmrvr_severity_family_nested_metrics.csv'));
writetable(summary,fullfile(resultsDir,'fmrvr_severity_family_nested_summary.csv'));
writetable(selections,fullfile(resultsDir,'fmrvr_severity_family_nested_selections.csv'));
writetable(perOutput,fullfile(resultsDir,'fmrvr_severity_family_nested_per_output.csv'));
writetable(familySummary,fullfile(resultsDir,'fmrvr_severity_family_nested_family_summary.csv'));
make_figure(outer,familySummary,figuresDir);
report=struct('metrics',outer,'summary',summary,'selections',selections,'family',familySummary);
fprintf('Severity/family FMRVR: baseline %.4f, structured %.4f, delta %+.4f, wins %d/10.\n', ...
    summary.baseline_mean_R2,summary.structured_mean_R2,summary.mean_delta_R2,summary.structured_wins);
end

function [p,s]=predict_auxiliary(Xtr,Xte,failure,severity,cfg)
[A,B]=classifier_features(Xtr,Xte,cfg);
classifier=fitclinear(A,double(failure),'Learner','logistic','Regularization','ridge','Lambda',.1);
[~,score]=predict(classifier,B); col=find(classifier.ClassNames==1,1);p=min(max(score(:,col),0),1);
ids=logical(failure); Z=[ones(sum(ids),1) A(ids,:)]; T=[ones(size(B,1),1) B];
P=eye(size(Z,2));P(1,1)=0;lambda=1;coef=(Z'*Z+lambda*P)\(Z'*severity(ids));
s=min(max(T*coef,0),1);
end

function gates=make_gates(p,s)
gates=[p sqrt(p) p.^2 min(1,p.*(.5+s)) min(1,p+.25*s) min(1,p+.5*p.*s)];
end

function names=gate_names()
names=["probability" "sqrt_probability" "squared_probability" ...
    "severity_scaled" "severity_additive" "severity_interaction"];
end

function summary=summarize_families(perOutput,dictionary)
summary=table;
for response=1:7
    rows=perOutput(perOutput.response==response & ~perOutput.constant,:);
    byRepeat=table;
    for repeat=unique(rows.repeat)'
        part=rows(rows.repeat==repeat,:);
        byRepeat=[byRepeat;table(repeat,mean(part.baseline_R2),mean(part.structured_R2), ...
            mean(part.delta_R2),'VariableNames',{'repeat','baseline_R2','structured_R2','delta_R2'})]; %#ok<AGROW>
    end
    summary=[summary;table(response,string(dictionary(response).name),mean(byRepeat.baseline_R2), ...
        mean(byRepeat.structured_R2),std(byRepeat.structured_R2),mean(byRepeat.delta_R2), ...
        sum(byRepeat.structured_R2>byRepeat.baseline_R2), ...
        'VariableNames',{'response','response_name','baseline_mean_R2','structured_mean_R2', ...
        'structured_sd_R2','mean_delta_R2','structured_wins'})]; %#ok<AGROW>
end
end

function make_figure(outer,family,figuresDir)
f=figure('Visible','off','Color','w','Position',[100 100 1000 430]);
subplot(1,2,1);plot(outer.repeat,outer.baseline_mean_R2,'-o','LineWidth',1.4);hold on;
plot(outer.repeat,outer.structured_mean_R2,'-s','LineWidth',1.4);yline(.7,':');grid on;
xlabel('Outer split');ylabel('Mean held-out R^2');legend('Binary-gated experts','Severity/family FMRVR','Location','best');
title('Matched nested validation');
subplot(1,2,2);bar(family.mean_delta_R2);grid on;set(gca,'XTick',1:7,'XTickLabel',family.response_name,'XTickLabelRotation',35);
ylabel('Mean delta R^2');title('Gain by response family');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_severity_family_nested_validation.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_severity_family_nested_validation.png'),'-dpng','-r220');close(f);
end

function [A,B]=classifier_features(A,B,cfg)
scale=median(abs(A),1);scale(scale<=eps)=1;
A=asinh(bsxfun(@rdivide,A,scale));B=asinh(bsxfun(@rdivide,B,scale));
xs=fit_task3_standardizer(A,cfg.preprocessing.constant_tolerance);
A=apply_task3_standardizer(A,xs);B=apply_task3_standardizer(B,xs);
end

function fold=stratified_folds(label,k,seed)
rng(seed,'twister');fold=zeros(numel(label),1);
for value=[false true]
    ids=find(label==value);ids=ids(randperm(numel(ids)));
    for j=1:numel(ids),fold(ids(j))=mod(j-1,k)+1;end
end
end
