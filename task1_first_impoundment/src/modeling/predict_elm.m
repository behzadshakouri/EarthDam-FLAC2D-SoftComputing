function yhat = predict_elm(model, X)
H = elm_activation(X*model.input_weights' + model.bias', model.activation);
yhat = H * model.output_weights;
end
