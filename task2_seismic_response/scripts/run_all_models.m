function results = run_all_models(models,cases,results_dir,production_override)
%RUN_ALL_MODELS Production FULL70 workflow based on the supplied codes.
root=setup_task2; cfg=task2_config(root);
% Apply user settings here as well so the production runner remains compatible
% with an older task2_config.m that may still be cached/on the MATLAB path.
if exist('task2_user_settings','file') == 2
 cfg=task2_user_settings(cfg);
end
pcfg=cfg.production;
if nargin>=4&&~isempty(production_override)
 if ~isstruct(production_override)
  error('Task2:InvalidProductionOverride','production_override must be a struct.');
 end
 names=fieldnames(production_override);
 for k=1:numel(names)
  pcfg.(names{k})=production_override.(names{k});
 end
end
% Verified FULL70 defaults. These fallbacks prevent an older configuration
% file from breaking a run; explicit user settings still take precedence.
if ~isfield(pcfg.elm,'hidden_neurons'),pcfg.elm.hidden_neurons=30;end
if ~isfield(pcfg.elm,'multistart_count'),pcfg.elm.multistart_count=30;end
if ~isfield(pcfg.elm,'validation_fraction'),pcfg.elm.validation_fraction=0.20;end
if ~isfield(pcfg.abc,'hidden_neurons'),pcfg.abc.hidden_neurons=15;end
if ~isfield(pcfg.acor,'hidden_neurons'),pcfg.acor.hidden_neurons=15;end
if ~isfield(pcfg.igwo,'hidden_neurons'),pcfg.igwo.hidden_neurons=5;end
if ~isfield(pcfg,'progress_every'),pcfg.progress_every=10;end
if ~isfield(pcfg,'make_case_plots'),pcfg.make_case_plots=true;end
if ~isfield(pcfg,'make_summary_plots'),pcfg.make_summary_plots=true;end
cfg.production=pcfg;
if nargin<1||isempty(models),models=pcfg.models;end
if ischar(models)||isstring(models),models=cellstr(models);end
if nargin<2||isempty(cases)
 cases=[repelem((1:cfg.num_points)',cfg.num_responses),repmat((1:cfg.num_responses)',cfg.num_points,1)];
end
validateattributes(cases,{'numeric'},{'2d','integer','positive','finite'},mfilename,'cases');
if size(cases,2)~=2
 error('Task2:InvalidCaseSelection','cases must be an N-by-2 matrix of [point response] rows.');
end
if any(cases(:,1)>cfg.num_points)||any(cases(:,2)>cfg.num_responses)
 error('Task2:InvalidCaseSelection','Case rows must be [point response] within P1-P%d and R1-R%d.',cfg.num_points,cfg.num_responses);
end
if nargin>=3&&~isempty(results_dir)
 cfg.results_dir=char(results_dir);
end
if ~exist(cfg.results_dir,'dir'),mkdir(cfg.results_dir);end
D=load(cfg.consolidated_file,'dataset');F=load(cfg.failure_file,'failure_data');
if exist(cfg.split_file,'file'),S=load(cfg.split_file,'split');split=S.split;else,split=create_realization_split(cfg);save(cfg.split_file,'split');end
allRows=table();
runClock=tic; totalRequested=numel(models)*size(cases,1); completedRequested=0;
for im=1:numel(models)
 method=upper(string(models{im})); methodDir=fullfile(cfg.results_dir,char(method));if ~exist(methodDir,'dir'),mkdir(methodDir);end
 effective_neurons=method_hidden_neurons(method,pcfg);
 fprintf('RUN CONFIG: %s hidden neurons = %d\n',method,effective_neurons);
 for icase=1:size(cases,1)
   p=cases(icase,1);r=cases(icase,2);
   caseFile=fullfile(methodDir,sprintf('P%d_R%d.mat',p,r));
   completedRequested=completedRequested+1;
   if pcfg.resume&&exist(caseFile,'file')
    S=load(caseFile,'case_result');cr=S.case_result;
    saved_neurons=checkpoint_hidden_neurons(cr);
    if isempty(saved_neurons)||saved_neurons~=effective_neurons
     error('Task2:CheckpointConfigurationMismatch', ...
      ['Checkpoint %s does not record the requested hidden-neuron count ', ...
       '(%d). Move/delete that checkpoint or use its original configuration.'], ...
      caseFile,effective_neurons);
    end
    allRows=[allRows;cr.metrics];fprintf('[resume %d/%d] %s P%d-R%d | neurons=%d\n',completedRequested,totalRequested,method,p,r,effective_neurons);continue;
   end
   fprintf('\n[%d/%d] %s P%d-R%d started\n',completedRequested,totalRequested,method,p,r);data=prepare_case_dataset(D.dataset,F.failure_data,split,p,r);
   % Preserve the FULL70 training reduction, but apply it only after the
   % reviewer-required realization split. The fixed test realizations are
   % never reduced or used to fit scaling.
   [Xdev,ydev,development_keep]=reduce_pga_per_template( ...
       data.X_development,data.y_development,pcfg.max_pga_per_template);
   fprintf('  development rows: %d -> %d (maxPGAperTemplate=%d)\n', ...
       size(data.X_development,1),size(Xdev,1),pcfg.max_pga_per_template);
   % Restore the author's FULL70 mapminmax transform, while fitting it only
   % on reduced development data. The fixed test realizations are apply-only.
   [Xd,sx]=fit_mapminmax_scaler(Xdev);[yd,sy]=fit_mapminmax_scaler(ydev);
   Xt=apply_mapminmax_scaler(data.X_test,sx);
   constant=isempty(data.y_development)||(max(data.y_development)-min(data.y_development))<=eps(max(1,max(abs(data.y_development)))); t=tic; history=[];
   selection=[];
   eo=pcfg.elm;
   switch method
    case "ELMABC",eo.hidden_neurons=pcfg.abc.hidden_neurons;
    case "ELMACOR",eo.hidden_neurons=pcfg.acor.hidden_neurons;
    case "ELMIGWO",eo.hidden_neurons=pcfg.igwo.hidden_neurons;
   end
   if constant
    model=[];pred=repmat(mean(ydev),size(data.y_test));
   else
    seed=cfg.seed+100*p+r;rng(seed,'twister');
    if method=="ELM"
     reduced_sim_ids=data.development_sim_ids(development_keep);
     [model,selection]=train_elm_multistart(Xd,yd,reduced_sim_ids,eo,seed);
    else
     nfit=min(size(Xd,1),pcfg.max_fit_samples);idx=randperm(size(Xd,1),nfit);Xf=Xd(idx,:);yf=yd(idx);
     initial=train_elm(Xf,yf,eo,seed);x0=[initial.input_weights(:);initial.bias(:)];
     span=min(pcfg.bound_cap,max(1,pcfg.bound_scale*max(abs(x0))));lb=-span;ub=span;
     cost=@(x)elm_candidate_cost(x,Xf,yf,eo);
     switch method,case "ELMABC",oo=pcfg.abc;case "ELMACOR",oo=pcfg.acor;case "ELMIGWO",oo=pcfg.igwo;otherwise,error('Unknown model %s',method);end
     progress=struct('every',pcfg.progress_every,'case_label',sprintf('%s P%d-R%d',method,p,r));
     [x,history]=optimize_elm_weights(method,x0,lb,ub,cost,oo,progress);model=elm_candidate_model(x,Xd,yd,eo);
    end
    predz=predict_elm(model,Xt);pred=reverse_mapminmax_scaler(predz,sy);pred=max(0,pred);
   end
   train_s=toc(t);m=calculate_regression_metrics(data.y_test,pred);
   metrics=table(method,p,r,effective_neurons,m.n,m.R2,m.nRMSE,m.nMAE,m.a10,m.a10_eligible,m.constant_reference,train_s, ...
    'VariableNames',{'model','point','response','hidden_neurons','n_test','R2','nRMSE','nMAE','a10','a10_eligible','constant_reference','train_s'});
   cr=struct('method',char(method),'point',p,'response',r,'model',model,'x_scaler',sx,'y_scaler',sy,'metrics',metrics,'history',history,'selection',selection,'split',split, ...
       'hidden_neurons',effective_neurons,'effective_options',eo, ...
       'max_pga_per_template',pcfg.max_pga_per_template,'development_keep',development_keep);
   if pcfg.save_predictions,cr.y_test=data.y_test;cr.y_pred=pred;cr.test_rows=data.test_rows;cr.test_sim_ids=data.test_sim_ids;cr.test_step=data.test_step;end
   case_result=cr;save(caseFile,'case_result','-v7.3');allRows=[allRows;metrics];
   if pcfg.make_case_plots,plot_task2_case_result(cr,cfg.results_dir);end
   elapsedRun=toc(runClock); eta=elapsedRun/completedRequested*(totalRequested-completedRequested);
   fprintf('[done] %s P%d-R%d | %.1f min | R2=%.4f | run ETA %s\n',method,p,r,train_s/60,m.R2,format_duration(eta));
 end
end
% Rebuild from all saved checkpoints so staged calls cannot erase earlier
% methods from the shared aggregate files.
[results,aggregate_report]=rebuild_all_four_method_aggregates(cfg.results_dir); %#ok<NASGU>
if pcfg.make_summary_plots && ~isempty(results),plot_task2_summary(results,cfg.results_dir);end
fprintf('Completed %d model-cases.\n',height(results));
end
function n=method_hidden_neurons(method,pcfg)
switch upper(string(method))
 case "ELM",n=pcfg.elm.hidden_neurons;
 case "ELMABC",n=pcfg.abc.hidden_neurons;
 case "ELMACOR",n=pcfg.acor.hidden_neurons;
 case "ELMIGWO",n=pcfg.igwo.hidden_neurons;
 otherwise,error('Task2:UnknownMethod','Unknown method %s.',method);
end
validateattributes(n,{'numeric'},{'scalar','integer','positive','finite'});
end
function n=checkpoint_hidden_neurons(cr)
n=[];
if isfield(cr,'hidden_neurons'),n=double(cr.hidden_neurons);return;end
if isfield(cr,'model')&&isstruct(cr.model)&&isfield(cr.model,'hidden_neurons')
 n=double(cr.model.hidden_neurons);
end
end
function s=format_duration(x)
if ~isfinite(x)||x<0,s='unknown';return;end
h=floor(x/3600);m=floor(mod(x,3600)/60);s=sprintf('%dh %02dm',h,m);
end
