function model = train_elm(X, y, options, seed)
%TRAIN_ELM Ridge-regularized single-hidden-layer ELM.
% Method lineage: the authors' original FULL70 workflow instantiated the
% LabCISNE ELMToolbox class (https://github.com/labcisne/ELMToolbox).
% This project-local functional implementation is not a verbatim copy. It
% adds deterministic initialization and an explicit ridge output solution.
rng(seed, 'twister');
[~,d] = size(X); h = options.hidden_neurons;
model.input_weights = 2*rand(h,d)-1; model.bias = 2*rand(h,1)-1;
H = elm_activation(X*model.input_weights' + model.bias', options.activation);
model.output_weights = (H'*H + options.ridge*eye(h)) \ (H'*y);
model.activation = options.activation; model.hidden_neurons = h;
end
