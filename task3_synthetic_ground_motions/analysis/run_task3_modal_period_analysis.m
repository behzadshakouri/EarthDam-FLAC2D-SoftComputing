function report=run_task3_modal_period_analysis()
%RUN_TASK3_MODAL_PERIOD_ANALYSIS Estimate dominant periods from stable development runs.
analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir); addpath(root); setup_task3; cfg=task3_config(root);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
tablesDir=fullfile(task3_output_root(root),'tables');
if ~isfolder(figuresDir),mkdir(figuresDir);end
if ~isfolder(tablesDir),mkdir(tablesDir);end
prepared=load(fullfile(task3_results_root(root),'final_production','task3_prepared_dataset.mat'),'dataset','qc');
saved=load(fullfile(resultsDir,'task3_manuscript_model.mat'),'developmentIds','testIds');
raw=load(cfg.raw.task3_data_file,'Task3'); Task3=raw.Task3;
stableDev=saved.developmentIds(~any(prepared.qc.truncated(saved.developmentIds,:),2));
assert(numel(stableDev)>=60,'Too few stable development records for transfer analysis.');

freq=logspace(log10(.2),log10(20),240)'; familyNames=["Horizontal displacement" "Vertical displacement" "Horizontal normal stress" ...
    "Vertical normal stress" "Pore-water pressure" "Incremental shear strain" "Incremental volumetric strain"];
familyMedian=nan(numel(freq),7);familyLow=familyMedian;familyHigh=familyMedian;curveCount=zeros(7,1);
for r=1:7
    curves=[];
    for ii=1:numel(stableDev)
        id=stableDev(ii); tout=double(Task3.Outputs.dytime{id}(:)); gm=Task3.Inputs.InputsMatrix(id);
        ain=interp1(double(gm.time(:)),double(gm.accel(:)),tout,'linear',0);
        for p=1:10
            y=double(Task3.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){id}(:));
            if numel(y)~=numel(tout) || std(y)<=cfg.preprocessing.constant_tolerance,continue;end
            c=transfer_shape(tout,ain,y,freq);if all(isfinite(c)),curves(end+1,:)=c';end %#ok<AGROW>
        end
    end
    curveCount(r)=size(curves,1); familyMedian(:,r)=median(curves,1)';
    familyLow(:,r)=column_percentile(curves,25)';familyHigh(:,r)=column_percentile(curves,75)';
end

Z=familyMedian;for r=1:7,Z(:,r)=(Z(:,r)-median(Z(:,r)))/max(iqr_local(Z(:,r)),eps);end
consensus=median(Z,2); consensus=movmean(consensus,5);
peakIdx=select_peaks(freq,consensus,3,.13); periods=1./freq(peakIdx); [periods,ord]=sort(periods,'descend');peakIdx=peakIdx(ord);
modal=table((1:numel(peakIdx))',freq(peakIdx),periods,consensus(peakIdx), ...
    'VariableNames',{'mode_rank','frequency_Hz','period_s','consensus_score'});
familyPeakPeriod=nan(height(modal),7);
for k=1:height(modal)
    near=abs(log10(freq)-log10(modal.frequency_Hz(k)))<=.12;
    ids=find(near);
    for r=1:7,[~,j]=max(familyMedian(ids,r));familyPeakPeriod(k,r)=1/freq(ids(j));end
end
modal.family_period_min_s=min(familyPeakPeriod,[],2);modal.family_period_max_s=max(familyPeakPeriod,[],2);
consistency=array2table([(1:height(modal))' familyPeakPeriod],'VariableNames', ...
    [{'mode_rank'} cellstr(compose('family_%d_period_s',1:7))]);
curvesTable=table(freq,1./freq,consensus,'VariableNames',{'frequency_Hz','period_s','consensus_score'});
for r=1:7
    curvesTable.(sprintf('family_%d_median',r))=familyMedian(:,r);
    curvesTable.(sprintf('family_%d_q25',r))=familyLow(:,r);curvesTable.(sprintf('family_%d_q75',r))=familyHigh(:,r);
end
writetable(modal,fullfile(resultsDir,'modal_periods_development_only.csv'));
writetable(consistency,fullfile(resultsDir,'modal_period_family_consistency.csv'));
writetable(curvesTable,fullfile(resultsDir,'modal_transfer_curves.csv'));

% Test whether exact modal-period ordinates add predictive information.
[Xaug,~,groups]=build_task3_augmented_features(Task3,cfg);[Xdense,~,densePeriods]=build_task3_dense_spectral_features(Task3,cfg);
modalPeriods=unique([periods(:);.5*periods(:);2*periods(:)]);modalPeriods=modalPeriods(modalPeriods>=.05 & modalPeriods<=5);
modalSa=nan(cfg.num_realizations,numel(modalPeriods));
for i=1:cfg.num_realizations
    modalSa(i,:)=exp(interp1(log(densePeriods),log(max(Xdense(i,11:end),eps)),log(modalPeriods),'linear','extrap'));
end
Xsets={Xaug(:,groups.spectral),[Xaug(:,groups.spectral) modalSa],Xdense};setNames=["spectral16" "modal_augmented" "dense35"];
Y=build_task3_screened_targets(Task3,prepared.dataset,prepared.qc,cfg,5);dev=saved.developmentIds(:);test=saved.testIds(:);
fold=make_folds(numel(dev),5,cfg.seed+2001);lambdas=[.1 1 10 100];ranks=[3 5 10 Inf];candidates=table;
for g=1:numel(Xsets)
    for lambda=lambdas
        for rank=ranks
            pred=nan(numel(dev),size(Y,2));
            for f=1:5
                tr=dev(fold~=f);va=dev(fold==f);
                m=fit_rrr(Xsets{g}(tr,:),Y(tr,:),lambda,rank,cfg);
                pred(fold==f,:)=predict_rrr(m,Xsets{g}(va,:));
            end
            mt=calculate_task3_metrics(Y(dev,:),pred,cfg.preprocessing.constant_tolerance);use=~[mt.constant];
            candidates=[candidates;table(setNames(g),size(Xsets{g},2),lambda,rank,mean([mt(use).R2]),mean([mt(use).nRMSE]), ...
                'VariableNames',{'feature_set','feature_count','lambda','rank','oof_mean_R2','oof_mean_nRMSE'})]; %#ok<AGROW>
        end
    end
end
[~,best]=min(candidates.oof_mean_nRMSE);g=find(setNames==candidates.feature_set(best));
model=fit_rrr(Xsets{g}(dev,:),Y(dev,:),candidates.lambda(best),candidates.rank(best),cfg);pred=predict_rrr(model,Xsets{g}(test,:));
mt=calculate_task3_metrics(Y(test,:),pred,cfg.preprocessing.constant_tolerance);use=~[mt.constant];
summary=table(candidates.feature_set(best),candidates.feature_count(best),candidates.lambda(best),candidates.rank(best), ...
    mean([mt(use).R2]),median([mt(use).R2]),mean([mt(use).nRMSE]),sum([mt(use).R2]>=.8),sum([mt(use).R2]>=.9), ...
    'VariableNames',{'selected_feature_set','feature_count','lambda','rank','test_mean_R2','test_median_R2','test_mean_nRMSE','outputs_R2_ge_08','outputs_R2_ge_09'});
writetable(candidates,fullfile(resultsDir,'modal_feature_development_cv.csv'));writetable(summary,fullfile(resultsDir,'modal_feature_test_summary.csv'));
make_figure(freq,familyMedian,consensus,peakIdx,familyNames,figuresDir);
write_latex(modal,numel(stableDev),curveCount,fullfile(tablesDir,'modal_periods.tex'));
report.modal_periods=modal;report.feature_summary=summary;report.curve_count=curveCount;
fprintf('Modal analysis: periods %s s; selected %s, fixed-test R2 %.4f.\n',mat2str(periods',4),summary.selected_feature_set,summary.test_mean_R2);
end

function c=transfer_shape(t,a,y,grid)
dt=median(diff(t));a=detrend(a);y=detrend(y);n=numel(t);w=.5-.5*cos(2*pi*(0:n-1)'/max(n-1,1));
nfft=2^nextpow2(n);A=fft(a.*w,nfft);Y=fft(y.*w,nfft);f=(0:nfft/2)'/(nfft*dt);A=abs(A(1:nfft/2+1));Y=abs(Y(1:nfft/2+1));
use=f>=min(grid) & f<=max(grid);f=f(use);A=A(use);Y=Y(use);floorA=percentile(A,25);h=Y./max(A,floorA+eps);
logf=log10(f);v=log10(h+eps);baseline=polyval(polyfit(logf,v,3),logf);v=movmean(v-baseline,5);
c=interp1(logf,v,log10(grid),'linear','extrap');
end
function idx=select_peaks(freq,value,count,minLogSeparation)
cand=find(value(2:end-1)>value(1:end-2)&value(2:end-1)>=value(3:end))+1;[~,order]=sort(value(cand),'descend');idx=[];
for k=1:numel(order),j=cand(order(k));if isempty(idx)||all(abs(log10(freq(j))-log10(freq(idx)))>=minLogSeparation),idx(end+1)=j;end %#ok<AGROW>
if numel(idx)==count,break;end,end
end
function q=column_percentile(X,p),q=zeros(1,size(X,2));for j=1:size(X,2),q(j)=percentile(X(:,j),p);end,end
function v=percentile(x,p),x=sort(x(isfinite(x)));z=1+(numel(x)-1)*p/100;lo=floor(z);hi=ceil(z);if lo==hi,v=x(lo);else,v=x(lo)+(z-lo)*(x(hi)-x(lo));end,end
function v=iqr_local(x),v=percentile(x,75)-percentile(x,25);end
function model=fit_rrr(X,Y,lambda,rank,cfg)
model.scale=median(abs(X),1);model.scale(model.scale<=eps)=1;X=asinh(bsxfun(@rdivide,X,model.scale));model.xs=fit_task3_standardizer(X,cfg.preprocessing.constant_tolerance);model.ys=fit_task3_standardizer(Y,cfg.preprocessing.constant_tolerance);
X=apply_task3_standardizer(X,model.xs);Y=apply_task3_standardizer(Y,model.ys);A=[ones(size(X,1),1) X];P=eye(size(A,2));P(1,1)=0;B=(A'*A+lambda*P)\(A'*Y);
if isfinite(rank)&&rank<size(Y,2),F=A*B;[~,~,V]=svd(F,'econ');V=V(:,1:min(rank,size(V,2)));B=B*(V*V');end;model.beta=B;
end
function Y=predict_rrr(model,X),X=apply_task3_standardizer(asinh(bsxfun(@rdivide,X,model.scale)),model.xs);Y=reverse_task3_standardizer([ones(size(X,1),1) X]*model.beta,model.ys);end
function fold=make_folds(n,k,seed),rng(seed,'twister');o=randperm(n);fold=zeros(n,1);for i=1:n,fold(o(i))=mod(i-1,k)+1;end,end
function make_figure(freq,family,consensus,peaks,names,outDir)
period=1./freq;[period,order]=sort(period,'ascend');
peakPeriods=1./freq(peaks);peakScores=consensus(peaks);
f=figure('Visible','off','Color','w','Position',[100 100 980 650]);subplot(2,1,1);hold on;
for r=1:7,plot(period,family(order,r),'LineWidth',1.2,'DisplayName',names(r));end
xlim([period(1) period(end)]);set(gca,'XScale','log','XDir','normal');grid on;xlabel('Period (s)');ylabel('Detrended log transfer');title('Sentinel-free development simulations');legend('Location','eastoutside');
subplot(2,1,2);plot(period,consensus(order),'k','LineWidth',1.8);hold on;scatter(peakPeriods,peakScores,65,'filled');
for k=1:numel(peaks),text(1/freq(peaks(k)),consensus(peaks(k)),sprintf('  T%d=%.3f s',k,1/freq(peaks(k))));end
xlim([period(1) period(end)]);set(gca,'XScale','log','XDir','normal');grid on;xlabel('Period (s)');ylabel('Consensus peak score');title('Modal-period candidates');set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'modal_period_transfer_analysis.pdf'),'-dpdf','-painters','-bestfit');print(f,fullfile(outDir,'modal_period_transfer_analysis.png'),'-dpng','-r220');close(f);
end
function write_latex(modal,nRecords,counts,path)
fid=fopen(path,'w');assert(fid>0);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'\\begin{table}[htbp]\n\\centering\n\\caption{Development-only transfer-function modal-period candidates.}\n\\label{tab:modal_periods}\n\\begin{tabular}{rrrrr}\n\\hline\nMode no. & Frequency (Hz) & Period (s) & Family range (s) & Consensus score \\\\\n\\hline\n');
for i=1:height(modal),fprintf(fid,'%d & %.3f & %.3f & %.3f--%.3f & %.3f \\\\\n',modal.mode_rank(i),modal.frequency_Hz(i),modal.period_s(i),modal.family_period_min_s(i),modal.family_period_max_s(i),modal.consensus_score(i));end
fprintf(fid,'\\hline\n\\end{tabular}\n\\begin{flushleft}\n\\footnotesize Estimated from %d simulations without a sentinel in the fixed development set using %d nonconstant record--point transfer curves. Modes are numbered from longest to shortest period; the standardized consensus score does not determine the numbering. The 45 fixed-test records were excluded.\n\\end{flushleft}\n\\end{table}\n',nRecords,sum(counts));
end
