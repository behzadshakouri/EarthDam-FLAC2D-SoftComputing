function summary = run_p7_r5_two_stage_experiment
%RUN_P7_R5_TWO_STAGE_EXPERIMENT Separate baseline and dynamic increment.
% Diagnostic experiment for P7-R5 only. The fixed realization-level split
% is retained and test outputs are never used during fitting or scaling.

root=setup_task2;
cfg=task2_config(root);
if exist('task2_user_settings','file')==2, cfg=task2_user_settings(cfg); end
pcfg=cfg.production;
out_dir=fullfile(root,'results','p7_r5_two_stage_experiment');
if ~exist(out_dir,'dir'), mkdir(out_dir); end

D=load(cfg.consolidated_file,'dataset');
F=load(cfg.failure_file,'failure_data');
S=load(cfg.split_file,'split');
data=prepare_case_dataset(D.dataset,F.failure_data,S.split,7,5);

% One baseline value and one physical-input row per realization.
[dev_ids,Xb_dev,yb_dev]=extract_baselines(data.X_development, ...
    data.y_development,data.development_sim_ids,data.development_step);
[test_ids,Xb_test,yb_test]=extract_baselines(data.X_test, ...
    data.y_test,data.test_sim_ids,data.test_step);

% Dynamic increment relative to each realization's own first admissible
% response. The observed test baseline is retained only for diagnostics;
% reconstructed predictions use the predicted baseline.
db_dev=subtract_by_id(data.y_development,data.development_sim_ids,dev_ids,yb_dev);
db_test=subtract_by_id(data.y_test,data.test_sim_ids,test_ids,yb_test);
db_dev=max(0,db_dev); db_test=max(0,db_test);

[Xi_dev,di_dev,keep]=reduce_pga_per_template(data.X_development, ...
    db_dev,pcfg.max_pga_per_template);
increment_sim_ids=data.development_sim_ids(keep);

methods={'ELM','ELMIGWO'};
summary=table();
for im=1:numel(methods)
    method=methods{im};
    if strcmp(method,'ELM'), neurons=30; else, neurons=5; end
    fprintf('\n====================================================\n');
    fprintf('P7-R5 two-stage %s | baseline + dynamic increment\n',method);
    fprintf('Hidden neurons: %d\n',neurons);
    fprintf('====================================================\n');
    clock=tic;

    % Fit baseline model from the 15 physical variables only.
    [Zb,sxb]=fit_mapminmax_scaler(Xb_dev);
    [tb,syb]=fit_mapminmax_scaler(yb_dev);
    Zb_test=apply_mapminmax_scaler(Xb_test,sxb);
    [baseline_model,baseline_history,baseline_selection]=fit_component( ...
        method,Zb,tb,dev_ids,neurons,pcfg,cfg.seed+70501,'P7-R5 baseline');
    baseline_pred=reverse_mapminmax_scaler( ...
        predict_elm(baseline_model,Zb_test),syb);
    baseline_pred=max(0,baseline_pred);

    % Fit the nonnegative dynamic increment model.
    [Zi,sxi]=fit_mapminmax_scaler(Xi_dev);
    [ti,syi]=fit_mapminmax_scaler(di_dev);
    Zi_test=apply_mapminmax_scaler(data.X_test,sxi);
    [increment_model,increment_history,increment_selection]=fit_component( ...
        method,Zi,ti,increment_sim_ids,neurons,pcfg,cfg.seed+70502, ...
        'P7-R5 increment');
    increment_pred=reverse_mapminmax_scaler( ...
        predict_elm(increment_model,Zi_test),syi);
    increment_pred=max(0,increment_pred);

    baseline_by_row=expand_by_id(data.test_sim_ids,test_ids,baseline_pred);
    y_pred=max(0,baseline_by_row+increment_pred);
    elapsed=toc(clock);
    m=calculate_regression_metrics(data.y_test,y_pred);
    mb=calculate_regression_metrics(yb_test,baseline_pred);
    md=calculate_regression_metrics(db_test,increment_pred);

    row=table(string(method),neurons,m.R2,m.nRMSE,m.nMAE,m.a10, ...
        mb.R2,mb.nRMSE,mb.nMAE,mb.a10,md.R2,md.nRMSE,md.nMAE,md.a10, ...
        elapsed,'VariableNames',{'model','hidden_neurons','R2','nRMSE', ...
        'nMAE','a10','baseline_R2','baseline_nRMSE','baseline_nMAE', ...
        'baseline_a10','increment_R2','increment_nRMSE','increment_nMAE', ...
        'increment_a10','train_s'});
    summary=[summary;row]; %#ok<AGROW>

    result=struct('method',method,'point',7,'response',5, ...
        'hidden_neurons',neurons,'metrics',row, ...
        'baseline_model',baseline_model,'increment_model',increment_model, ...
        'baseline_x_scaler',sxb,'baseline_y_scaler',syb, ...
        'increment_x_scaler',sxi,'increment_y_scaler',syi, ...
        'baseline_history',baseline_history, ...
        'increment_history',increment_history, ...
        'baseline_selection',baseline_selection, ...
        'increment_selection',increment_selection, ...
        'test_sim_ids',data.test_sim_ids,'test_step',data.test_step, ...
        'y_test',data.y_test,'y_pred',y_pred, ...
        'test_baseline',yb_test,'predicted_baseline',baseline_pred, ...
        'test_increment',db_test,'predicted_increment',increment_pred, ...
        'development_keep',keep,'split',S.split);
    save(fullfile(out_dir,sprintf('%s_P7_R5_two_stage.mat',method)), ...
        'result','-v7.3');
    write_realization_metrics(result,cfg,out_dir);
    plot_two_stage_histories(result,cfg,out_dir);
    writetable(summary,fullfile(out_dir,'p7_r5_two_stage_summary.csv'));
    fprintf('[done] %s | R2=%.4f | nRMSE=%.4f | nMAE=%.4f | a10=%.4f\n', ...
        method,m.R2,m.nRMSE,m.nMAE,m.a10);
end

disp(summary);
fprintf('\nSummary written to:\n%s\n', ...
    fullfile(out_dir,'p7_r5_two_stage_summary.csv'));
end

function [ids,Xbase,ybase]=extract_baselines(X,y,sim_ids,steps)
ids=unique(double(sim_ids(:)),'stable');
Xbase=zeros(numel(ids),15); ybase=zeros(numel(ids),1);
for i=1:numel(ids)
    q=find(double(sim_ids(:))==ids(i));
    [~,j]=min(double(steps(q)));
    k=q(j); Xbase(i,:)=double(X(k,1:15)); ybase(i)=double(y(k));
end
end

function delta=subtract_by_id(y,row_ids,ids,baseline)
base=expand_by_id(row_ids,ids,baseline);
delta=double(y(:))-base;
end

function values=expand_by_id(row_ids,ids,per_id)
[tf,loc]=ismember(double(row_ids(:)),double(ids(:)));
assert(all(tf),'A realization ID has no baseline value.');
values=double(per_id(loc));
end

function [model,history,selection]=fit_component(method,X,y,sim_ids,neurons,pcfg,seed,label)
eo=pcfg.elm; eo.hidden_neurons=neurons;
history=[]; selection=[];
if strcmp(method,'ELM')
    [model,selection]=train_elm_multistart(X,y,sim_ids,eo,seed);
    return;
end
rng(seed,'twister');
nfit=min(size(X,1),pcfg.max_fit_samples);
idx=randperm(size(X,1),nfit); Xf=X(idx,:); yf=y(idx);
initial=train_elm(Xf,yf,eo,seed);
x0=[initial.input_weights(:);initial.bias(:)];
span=min(pcfg.bound_cap,max(1,pcfg.bound_scale*max(abs(x0))));
lb=-span; ub=span;
cost=@(x)elm_candidate_cost(x,Xf,yf,eo);
progress=struct('every',pcfg.progress_every,'case_label',label);
[x,history]=optimize_elm_weights('ELMIGWO',x0,lb,ub,cost,pcfg.igwo,progress);
model=elm_candidate_model(x,X,y,eo);
end

function write_realization_metrics(result,cfg,out_dir)
ids=unique(double(result.test_sim_ids(:)),'stable'); rows=table();
for i=1:numel(ids)
    v=double(result.test_sim_ids(:))==ids(i);
    m=calculate_regression_metrics(result.y_test(v),result.y_pred(v));
    row=table(string(result.method),ids(i),sum(v),m.R2,m.nRMSE,m.nMAE,m.a10, ...
        'VariableNames',{'model','simulation_id','n','R2','nRMSE','nMAE','a10'});
    rows=[rows;row]; %#ok<AGROW>
end
writetable(rows,fullfile(out_dir,sprintf('%s_P7_R5_by_realization.csv',result.method)));
end

function plot_two_stage_histories(result,cfg,out_dir)
ids=unique(double(result.test_sim_ids(:)),'stable'); score=nan(numel(ids),1);
for i=1:numel(ids)
    v=double(result.test_sim_ids(:))==ids(i);
    m=calculate_regression_metrics(result.y_test(v),result.y_pred(v));
    score(i)=m.nRMSE;
end
[~,o]=sort(score,'ascend'); o=o(isfinite(score(o)));
if isempty(o),return;end
pick=[o(1),o(round((numel(o)+1)/2)),o(end)]; labels={'Best','Median','Worst'};
f=figure('Visible','off','Color','w','Position',[100 100 1050 760]);
for k=1:3
    v=double(result.test_sim_ids(:))==ids(pick(k));
    st=double(result.test_step(v)); yt=double(result.y_test(v)); yp=double(result.y_pred(v));
    [st,j]=sort(st);yt=yt(j);yp=yp(j);m=calculate_regression_metrics(yt,yp);
    subplot(3,1,k);plot(st*cfg.time_step_s,yt,'k-','LineWidth',1.15);hold on;
    plot(st*cfg.time_step_s,yp,'r--','LineWidth',1.05);grid on;box on;
    ylabel('Response');title(sprintf('%s: simulation %d, R^2=%.3f, nRMSE=%.3f', ...
        labels{k},ids(pick(k)),m.R2,m.nRMSE));
    if k==1,legend('FLAC2D','Two-stage prediction','Location','best');end
end
xlabel('Time (s)');sgtitle(sprintf('%s P7-R5 two-stage reconstruction',result.method));
print(f,fullfile(out_dir,sprintf('%s_P7_R5_two_stage_histories.png',result.method)), ...
    '-dpng','-r300');close(f);
end
