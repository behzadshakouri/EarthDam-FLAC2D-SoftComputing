function [model,selection] = train_elm_multistart(X,y,sim_ids,options,seed)
%TRAIN_ELM_MULTISTART Select a stable FULL70-form ELM without test leakage.
% Candidate hidden layers are evaluated on complete held-out development
% realizations. The selected hidden layer is finally refitted on all supplied
% development rows using the original ridge output-weight equation.

nstarts = options.multistart_count;
valfrac = options.validation_fraction;
ids = unique(sim_ids(:),'stable');
if numel(ids) < 5
    error('Task2:InsufficientDevelopmentIDs', ...
        'At least five development realizations are required for ELM selection.');
end
rng(seed+7919,'twister');
ids = ids(randperm(numel(ids)));
nval = max(1,min(numel(ids)-1,round(valfrac*numel(ids))));
val_ids = ids(1:nval);
is_val = ismember(sim_ids,val_ids);
is_fit = ~is_val;

scores = inf(nstarts,1);
models = cell(nstarts,1);
for k = 1:nstarts
    candidate = train_elm(X(is_fit,:),y(is_fit),options,seed+k-1);
    pv = predict_elm(candidate,X(is_val,:));
    scores(k) = sqrt(mean((pv-y(is_val)).^2));
    models{k} = candidate;
end
[best_score,best_index] = min(scores);
model = models{best_index};
H = elm_activation(X*model.input_weights' + model.bias',options.activation);
model.output_weights = (H'*H + options.ridge*eye(options.hidden_neurons))\(H'*y);
model.selection_seed = seed+best_index-1;

selection = struct('strategy','development_realization_multistart', ...
    'candidate_count',nstarts,'validation_fraction',valfrac, ...
    'validation_ids',val_ids,'validation_rmse_scaled',best_score, ...
    'selected_candidate',best_index,'candidate_rmse_scaled',scores);
end
