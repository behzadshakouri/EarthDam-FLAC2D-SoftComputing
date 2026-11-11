function report = explore_task3_advanced_models()
%EXPLORE_TASK3_ADVANCED_MODELS OOF screening of nonlinear models and blends.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
X=prepared.dataset.X; Y=screened.Y; dev=saved.developmentIds; test=saved.testIds;
fold=make_folds(numel(dev),5,cfg.seed+901);
baseNames=["asinhX ridge";"RF leaf5 mtry3";"RF leaf5 mtry9";"LSBoost";"ARD Matern52 GPR"];
oof=cell(numel(baseNames),1); for k=1:numel(oof),oof{k}=nan(numel(dev),cfg.num_outputs);end

for f=1:5
    trLocal=find(fold~=f); vaLocal=find(fold==f); tr=dev(trLocal); va=dev(vaLocal);
    prep=fit_preprocess(X(tr,:),Y(tr,:),cfg); Xtr=prep.Xs; Ytr=prep.Ys;
    Xva=apply_x(prep,X(va,:)); modeled=~prep.ys.constant;

    % Strongest development-only linear candidate from the first search.
    A=[ones(size(Xtr,1),1) Xtr]; penalty=eye(size(A,2)); penalty(1,1)=0;
    beta=(A'*A+penalty)\(A'*Ytr);
    oof{1}(vaLocal,:)=invert_y(prep,[ones(size(Xva,1),1) Xva]*beta);

    rng(cfg.seed+1000+f,'twister');
    for config=1:2
        mtry=[3 9]; z=zeros(numel(va),cfg.num_outputs);
        for j=find(modeled)
            m=TreeBagger(150,Xtr,Ytr(:,j),'Method','regression','MinLeafSize',5, ...
                'NumPredictorsToSample',mtry(config),'OOBPrediction','off');
            z(:,j)=predict(m,Xva);
        end
        oof{1+config}(vaLocal,:)=invert_y(prep,z);
    end

    z=zeros(numel(va),cfg.num_outputs);
    tree=templateTree('MaxNumSplits',10,'MinLeafSize',5);
    for j=find(modeled)
        m=fitrensemble(Xtr,Ytr(:,j),'Method','LSBoost','NumLearningCycles',200, ...
            'LearnRate',0.05,'Learners',tree);
        z(:,j)=predict(m,Xva);
    end
    oof{4}(vaLocal,:)=invert_y(prep,z);

    z=zeros(numel(va),cfg.num_outputs);
    for j=find(modeled)
        m=fitrgp(Xtr,Ytr(:,j),'KernelFunction','ardmatern52','BasisFunction','linear', ...
            'Standardize',false,'FitMethod','exact','PredictMethod','exact');
        z(:,j)=predict(m,Xva);
    end
    oof{5}(vaLocal,:)=invert_y(prep,z);
    save(fullfile(resultsDir,'advanced_model_oof_checkpoint.mat'),'oof','fold','baseNames','-v7.3');
    fprintf('Advanced-model OOF fold %d/5 complete.\n',f);
end

candidateNames=baseNames; candidatePred=oof; candidateDetail=repmat("base",numel(baseNames),1);
for other=2:numel(baseNames)
    for alpha=0.1:0.1:0.9
        candidateNames(end+1)=sprintf('Blend %.1f ridge + %.1f %s',alpha,1-alpha,baseNames(other)); %#ok<AGROW>
        candidatePred{end+1}=alpha*oof{1}+(1-alpha)*oof{other}; %#ok<AGROW>
        candidateDetail(end+1)=sprintf('blend:%d:%.1f',other,alpha); %#ok<AGROW>
    end
end

cv=table;
for c=1:numel(candidateNames)
    mt=calculate_task3_metrics(Y(dev,:),candidatePred{c},cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    cv=[cv;table(c,candidateNames(c),candidateDetail(c),mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
        'VariableNames',{'candidate_id','candidate','detail','oof_mean_R2','oof_median_R2', ...
        'oof_mean_nRMSE','oof_mean_nMAE','oof_mean_a10'})]; %#ok<AGROW>
end
[~,best]=min(cv.oof_mean_nRMSE);

% Fit all bases once on the complete development set, then evaluate only the
% one configuration preselected above.
finalPred=fit_all_bases(X,Y,dev,test,cfg);
if startsWith(candidateDetail(best),"blend")
    parts=split(candidateDetail(best),':'); other=str2double(parts(2)); alpha=str2double(parts(3));
    selectedPrediction=alpha*finalPred{1}+(1-alpha)*finalPred{other};
else
    selectedPrediction=finalPred{best};
end
mt=calculate_task3_metrics(Y(test,:),selectedPrediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
testSummary=table(best,candidateNames(best),candidateDetail(best),mean([mt(use).R2]), ...
    median([mt(use).R2]),mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
    'VariableNames',{'candidate_id','candidate','detail','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10'});
perOutput=table((1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})', ...
    [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'});
writetable(cv,fullfile(resultsDir,'advanced_model_development_cv.csv'));
writetable(testSummary,fullfile(resultsDir,'advanced_model_test_summary.csv'));
writetable(perOutput,fullfile(resultsDir,'advanced_model_test_per_output.csv'));
save(fullfile(resultsDir,'advanced_model_selected.mat'),'cv','testSummary','selectedPrediction','fold','-v7.3');
make_figure(cv,best,figuresDir);
report.cv=cv; report.test=testSummary;
fprintf('Advanced selection: %s; OOF R2 %.4f; test R2 %.4f.\n', ...
    candidateNames(best),cv.oof_mean_R2(best),testSummary.mean_R2);
end

function prep=fit_preprocess(X,Y,cfg)
prep.xScale=median(abs(X),1); prep.xScale(prep.xScale<=eps)=1;
Xt=asinh(bsxfun(@rdivide,X,prep.xScale));
prep.xs=fit_task3_standardizer(Xt,cfg.preprocessing.constant_tolerance);
prep.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
prep.Xs=apply_task3_standardizer(Xt,prep.xs); prep.Ys=apply_task3_standardizer(Y,prep.ys);
end
function Xs=apply_x(prep,X), Xs=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,prep.xScale)),prep.xs); end
function Y=invert_y(prep,Z), Y=reverse_task3_standardizer(Z,prep.ys); end

function predictions=fit_all_bases(X,Y,dev,test,cfg)
prep=fit_preprocess(X(dev,:),Y(dev,:),cfg); Xtr=prep.Xs; Ytr=prep.Ys;
Xt=apply_x(prep,X(test,:)); modeled=~prep.ys.constant; predictions=cell(5,1);
A=[ones(size(Xtr,1),1) Xtr]; penalty=eye(size(A,2)); penalty(1,1)=0;
beta=(A'*A+penalty)\(A'*Ytr); predictions{1}=invert_y(prep,[ones(size(Xt,1),1) Xt]*beta);
rng(cfg.seed+1099,'twister');
for config=1:2
    mtry=[3 9]; z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled)
        m=TreeBagger(150,Xtr,Ytr(:,j),'Method','regression','MinLeafSize',5, ...
            'NumPredictorsToSample',mtry(config),'OOBPrediction','off'); z(:,j)=predict(m,Xt);
    end
    predictions{1+config}=invert_y(prep,z);
end
z=zeros(numel(test),cfg.num_outputs); tree=templateTree('MaxNumSplits',10,'MinLeafSize',5);
for j=find(modeled)
    m=fitrensemble(Xtr,Ytr(:,j),'Method','LSBoost','NumLearningCycles',200, ...
        'LearnRate',0.05,'Learners',tree); z(:,j)=predict(m,Xt);
end
predictions{4}=invert_y(prep,z);
z=zeros(numel(test),cfg.num_outputs);
for j=find(modeled)
    m=fitrgp(Xtr,Ytr(:,j),'KernelFunction','ardmatern52','BasisFunction','linear', ...
        'Standardize',false,'FitMethod','exact','PredictMethod','exact'); z(:,j)=predict(m,Xt);
end
predictions{5}=invert_y(prep,z);
end

function fold=make_folds(n,k,seed)
rng(seed,'twister'); order=randperm(n); fold=zeros(n,1);
for i=1:n, fold(order(i))=mod(i-1,k)+1; end
end
function make_figure(cv,best,outDir)
[~,order]=sort(cv.oof_mean_R2,'descend'); top=order(1:min(15,numel(order)));
f=figure('Visible','off','Color','w','Position',[100 100 1100 620]);
barh(categorical(cv.candidate(top),cv.candidate(top(end:-1:1))),cv.oof_mean_R2(top),'FaceColor',[0.10 0.35 0.62]);
xlabel('Development-only OOF mean R^2'); title(sprintf('Advanced model candidates; selected: %s',cv.candidate(best))); grid on;
set(gca,'FontSize',8); set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'advanced_model_development_cv.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'advanced_model_development_cv.png'),'-dpng','-r220'); close(f);
end
