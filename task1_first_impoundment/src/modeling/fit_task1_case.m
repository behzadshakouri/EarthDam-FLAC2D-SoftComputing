function R = fit_task1_case(X,y,method,hidden_neurons,split,cfg,seed)
%FIT_TASK1_CASE Fit and evaluate one paper method for one scalar target.
method=upper(string(method));
Xd=X(split.development,:); Xt=X(split.test,:);
yd=y(split.development); yt=y(split.test);
[Xdn,xs]=fit_mapminmax_scaler(Xd);
Xtn=apply_mapminmax_scaler(Xt,xs);
[ydn,ys]=fit_mapminmax_scaler(yd);
opt.hidden_neurons=hidden_neurons;
opt.activation=cfg.activation; opt.ridge=cfg.production.ridge;
if method=="ELM"
    model=train_elm(Xdn,ydn,opt,seed);
    history=[];
else
    initial=train_elm(Xdn,ydn,opt,seed);
    x0=[initial.input_weights(:);initial.bias(:)];
    lb=cfg.production.bound_min*ones(size(x0));
    ub=cfg.production.bound_max*ones(size(x0));
    cost=@(x) elm_candidate_cost(x,Xdn,ydn,opt);
    switch method
        case "ELMABC", optimizer=cfg.abc;
        case "ELMACOR", optimizer=cfg.acor;
        case "ELMIGWO", optimizer=cfg.igwo;
        otherwise, error('Task1:UnknownMethod','Unknown method %s.',method);
    end
    rng(seed,'twister');
    [best,history]=optimize_elm_weights(method,x0,lb,ub,cost,optimizer);
    model=elm_candidate_model(best,Xdn,ydn,opt);
end
pd=reverse_mapminmax_scaler(predict_elm(model,Xdn),ys);
pt=reverse_mapminmax_scaler(predict_elm(model,Xtn),ys);
R.method=char(method); R.model=model; R.scaler_x=xs; R.scaler_y=ys;
R.split=split; R.development_observed=yd; R.development_predicted=pd;
R.test_observed=yt; R.test_predicted=pt;
R.development_metrics=calculate_task1_metrics(yd,pd);
R.test_metrics=calculate_task1_metrics(yt,pt);
R.optimizer_history=history; R.seed=seed;
end
