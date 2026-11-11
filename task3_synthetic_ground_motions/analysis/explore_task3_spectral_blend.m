function report = explore_task3_spectral_blend()
%EXPLORE_TASK3_SPECTRAL_BLEND OOF-select a spectral ridge/forest blend.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset');
screened=load(fullfile(resultsDir,'task3_screened_targets.mat'),'Y');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [X,names,groups]=build_task3_augmented_features(raw.Task3,cfg);
X=X(:,groups.spectral); Y=screened.Y; dev=saved.developmentIds; test=saved.testIds;
fold=make_folds(numel(dev),5,cfg.seed+901); baseNames=["Spectral ridge";"Spectral RF mtry5";"Spectral RF mtry16"];
oof=cell(3,1); for k=1:3,oof{k}=nan(numel(dev),cfg.num_outputs);end
for f=1:5
    tr=dev(fold~=f); va=dev(fold==f); prep=fit_preprocess(X(tr,:),Y(tr,:),cfg);
    Xtr=prep.Xs; Xva=apply_x(prep,X(va,:)); Ytr=prep.Ys; modeled=~prep.ys.constant;
    A=[ones(size(Xtr,1),1) Xtr]; penalty=eye(size(A,2)); penalty(1,1)=0;
    beta=(A'*A+10*penalty)\(A'*Ytr); oof{1}(fold==f,:)=invert_y(prep,[ones(size(Xva,1),1) Xva]*beta);
    for config=1:2
        rng(cfg.seed+1200+10*config+f,'twister'); z=zeros(numel(va),cfg.num_outputs); mtry=[5 16];
        for j=find(modeled)
            m=TreeBagger(200,Xtr,Ytr(:,j),'Method','regression','MinLeafSize',5, ...
                'NumPredictorsToSample',mtry(config),'OOBPrediction','off'); z(:,j)=predict(m,Xva);
        end
        oof{1+config}(fold==f,:)=invert_y(prep,z);
    end
    fprintf('Spectral blend OOF fold %d/5 complete.\n',f);
end
candidate=baseNames; detail=["base:1";"base:2";"base:3"]; pred=oof;
for other=2:3
    for alpha=0.1:0.1:0.9
        candidate(end+1)=sprintf('Blend %.1f ridge + %.1f RF%d',alpha,1-alpha,other); %#ok<AGROW>
        detail(end+1)=sprintf('blend:%d:%.1f',other,alpha); pred{end+1}=alpha*oof{1}+(1-alpha)*oof{other}; %#ok<AGROW>
    end
end
cv=table;
for c=1:numel(candidate)
    mt=calculate_task3_metrics(Y(dev,:),pred{c},cfg.preprocessing.constant_tolerance); use=~[mt.constant];
    cv=[cv;table(c,candidate(c),detail(c),mean([mt(use).R2]),median([mt(use).R2]), ...
        mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]), ...
        'VariableNames',{'candidate_id','candidate','detail','oof_mean_R2','oof_median_R2', ...
        'oof_mean_nRMSE','oof_mean_nMAE','oof_mean_a10'})]; %#ok<AGROW>
end
[~,best]=min(cv.oof_mean_nRMSE); final=fit_final(X,Y,dev,test,cfg);
parts=split(detail(best),':');
if parts(1)=="base", prediction=final{str2double(parts(2))};
else, other=str2double(parts(2)); alpha=str2double(parts(3)); prediction=alpha*final{1}+(1-alpha)*final{other};end
mt=calculate_task3_metrics(Y(test,:),prediction,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(best,candidate(best),detail(best),mean([mt(use).R2]),median([mt(use).R2]), ...
    mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]),sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8), ...
    'VariableNames',{'candidate_id','candidate','detail','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08'});
writetable(cv,fullfile(resultsDir,'spectral_blend_development_cv.csv'));
writetable(summary,fullfile(resultsDir,'spectral_blend_test_summary.csv'));
writetable(table((1:cfg.num_outputs)',string({prepared.dataset.output_dictionary.label})', ...
    [mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'}), ...
    fullfile(resultsDir,'spectral_blend_test_per_output.csv'));
save(fullfile(resultsDir,'spectral_blend_selected.mat'),'cv','summary','prediction','names','groups','fold','-v7.3');
make_figure(cv,best,figuresDir); report.cv=cv;report.test=summary;
fprintf('Spectral blend selected %s: OOF R2 %.4f, test R2 %.4f.\n',candidate(best),cv.oof_mean_R2(best),summary.mean_R2);
end

function prep=fit_preprocess(X,Y,cfg)
prep.scale=median(abs(X),1);prep.scale(prep.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,prep.scale));
prep.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);prep.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
prep.Xs=apply_task3_standardizer(X,prep.xs);prep.Ys=apply_task3_standardizer(Y,prep.ys);
end
function X=apply_x(prep,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,prep.scale)),prep.xs);end
function Y=invert_y(prep,Z),Y=reverse_task3_standardizer(Z,prep.ys);end
function pred=fit_final(X,Y,dev,test,cfg)
prep=fit_preprocess(X(dev,:),Y(dev,:),cfg);Xd=prep.Xs;Xt=apply_x(prep,X(test,:));Yd=prep.Ys;modeled=~prep.ys.constant;pred=cell(3,1);
A=[ones(size(Xd,1),1) Xd];penalty=eye(size(A,2));penalty(1,1)=0;beta=(A'*A+10*penalty)\(A'*Yd);
pred{1}=invert_y(prep,[ones(size(Xt,1),1) Xt]*beta);mtry=[5 16];
for config=1:2
    rng(cfg.seed+1300+config,'twister');z=zeros(numel(test),cfg.num_outputs);
    for j=find(modeled),m=TreeBagger(200,Xd,Yd(:,j),'Method','regression','MinLeafSize',5,'NumPredictorsToSample',mtry(config),'OOBPrediction','off');z(:,j)=predict(m,Xt);end
    pred{1+config}=invert_y(prep,z);
end
end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
function make_figure(cv,best,outDir)
[~,order]=sort(cv.oof_mean_R2,'descend');top=order(1:min(15,numel(order)));f=figure('Visible','off','Color','w','Position',[100 100 1000 600]);
barh(categorical(cv.candidate(top),cv.candidate(top(end:-1:1))),cv.oof_mean_R2(top),'FaceColor',[0.10 0.35 0.62]);grid on;
xlabel('Development-only OOF mean R^2');title(sprintf('Spectral model candidates; selected: %s',cv.candidate(best)));set(gca,'FontSize',8);set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'spectral_blend_development_cv.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(outDir,'spectral_blend_development_cv.png'),'-dpng','-r220');close(f);
end
