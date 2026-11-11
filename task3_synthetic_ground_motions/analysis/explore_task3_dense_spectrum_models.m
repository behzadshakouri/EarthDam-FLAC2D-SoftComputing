function report=explore_task3_dense_spectrum_models()
%EXPLORE_TASK3_DENSE_SPECTRUM_MODELS Dense-spectrum reduced-rank regression.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); [Xdense,names,periods]=build_task3_dense_spectral_features(raw.Task3,cfg);
[Xaug,~,groups]=build_task3_augmented_features(raw.Task3,cfg);[Xfunctional,functionalNames]=build_task3_functional_features(raw.Task3,cfg);
Xsparse=Xaug(:,groups.spectral); Xpoly=Xsparse;
for j=1:size(Xsparse,2),for k=j:size(Xsparse,2),Xpoly(:,end+1)=Xsparse(:,j).*Xsparse(:,k);end,end %#ok<AGROW>
Xsets={Xsparse,Xdense,Xfunctional,Xpoly}; setNames=["sparse16" "dense35" "functional106" "spectral_poly152"];
Y=build_task3_screened_targets(raw.Task3,prepared.dataset,prepared.qc,cfg,5);
dev=saved.developmentIds(:); test=saved.testIds(:); fold=make_folds(numel(dev),5,cfg.seed+1801);
lambdas=[.01 .1 1 10 100]; ranks=[3 5 10 20 Inf]; rows=table; predictions={}; id=0;
for g=1:numel(Xsets)
    for lambda=lambdas
        for rank=ranks
            id=id+1; oof=nan(numel(dev),size(Y,2));
            for f=1:5
                tr=dev(fold~=f); va=dev(fold==f); model=fit_rrr(Xsets{g}(tr,:),Y(tr,:),lambda,rank,cfg);
                oof(fold==f,:)=predict_rrr(model,Xsets{g}(va,:));
            end
            predictions{id}=oof; %#ok<AGROW>
            mt=calculate_task3_metrics(Y(dev,:),oof,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
            rows=[rows;table(id,setNames(g),size(Xsets{g},2),lambda,rank,mean([mt(use).R2]),median([mt(use).R2]), ...
                mean([mt(use).nRMSE]),mean([mt(use).nMAE]),sum([mt(use).R2]>=.9), ...
                'VariableNames',{'candidate_id','feature_set','feature_count','lambda','rank','mean_R2','median_R2','mean_nRMSE','mean_nMAE','outputs_R2_ge_09'})]; %#ok<AGROW>
        end
    end
end
[~,best]=min(rows.mean_nRMSE); g=find(setNames==rows.feature_set(best));
model=fit_rrr(Xsets{g}(dev,:),Y(dev,:),rows.lambda(best),rows.rank(best),cfg);
pred=predict_rrr(model,Xsets{g}(test,:)); mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance); use=~[mt.constant];
summary=table(best,rows.feature_set(best),rows.lambda(best),rows.rank(best),mean([mt(use).R2]),median([mt(use).R2]), ...
    mean([mt(use).nRMSE]),mean([mt(use).nMAE]),mean([mt(use).a10]),sum([mt(use).R2]>=.7),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
    'VariableNames',{'candidate_id','feature_set','lambda','rank','mean_R2','median_R2','mean_nRMSE','mean_nMAE','mean_a10','outputs_R2_ge_07','outputs_R2_ge_08','outputs_R2_ge_09'});
writetable(rows,fullfile(resultsDir,'dense_spectrum_development_cv.csv')); writetable(summary,fullfile(resultsDir,'dense_spectrum_fixed_test_summary.csv'));
writetable(table((1:size(Y,2))',string({prepared.dataset.output_dictionary.label})',[mt.R2]',[mt.nRMSE]',[mt.nMAE]',[mt.a10]',[mt.constant]', ...
    'VariableNames',{'output_column','label','R2','nRMSE','nMAE','a10','constant'}),fullfile(resultsDir,'dense_spectrum_fixed_test_per_output.csv'));
save(fullfile(resultsDir,'dense_spectrum_selected_model.mat'),'model','rows','best','names','functionalNames','periods','fold','-v7.3');
f=figure('Visible','off','Color','w','Position',[100 100 900 470]); plotRank=rows.rank;plotRank(isinf(plotRank))=40;
scatter(plotRank,rows.mean_R2,45,rows.lambda,'filled'); set(gca,'XScale','log','ColorScale','log'); colorbar; grid on;
xlabel('Output rank (40 also denotes full rank)');ylabel('Five-fold OOF mean R^2');title('Ground-motion representation and reduced-rank search');set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'dense_spectrum_model_search.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(figuresDir,'dense_spectrum_model_search.png'),'-dpng','-r220');close(f);
report.summary=summary;report.candidates=rows;fprintf('Dense-spectrum model: fixed-test R2 %.4f; %d/67 outputs >=0.9.\n',summary.mean_R2,summary.outputs_R2_ge_09);
end
function model=fit_rrr(X,Y,lambda,rank,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));
model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;
B=(A'*A+lambda*P)\(A'*Y);model.projection=[];
if isfinite(rank) && rank<size(Y,2)
    fitted=A*B;[~,~,V]=svd(fitted,'econ');model.projection=V(:,1:min(rank,size(V,2)));B=B*model.projection*model.projection';
end
model.beta=B;
end
function Y=predict_rrr(model,X)
X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);
end
function fold=make_folds(n,k,seed),rng(seed,'twister');order=randperm(n);fold=zeros(n,1);for i=1:n,fold(order(i))=mod(i-1,k)+1;end,end
