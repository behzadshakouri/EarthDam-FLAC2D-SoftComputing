function cost = elm_candidate_cost(x, X, y, options)
model = elm_candidate_model(x, X, y, options);
p = predict_elm(model, X);
cost = sqrt(mean((p-y).^2));
if ~isfinite(cost), cost = realmax; end
end
