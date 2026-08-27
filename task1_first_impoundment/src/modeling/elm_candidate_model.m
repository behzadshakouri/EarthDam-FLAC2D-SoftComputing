function model = elm_candidate_model(x, X, y, options)
%ELM_CANDIDATE_MODEL Decode Win/b and solve ridge output weights.
d = size(X,2); h = options.hidden_neurons;
nw = d*h;
model.input_weights = reshape(x(1:nw), h, d);
model.bias = x(nw+1:nw+h);
H = elm_activation(X*model.input_weights' + model.bias', options.activation);
model.output_weights = (H'*H + options.ridge*eye(h)) \ (H'*y);
model.activation = options.activation;
model.hidden_neurons = h;
end
