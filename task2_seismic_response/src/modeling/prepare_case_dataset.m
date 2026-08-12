function data = prepare_case_dataset(dataset, failure_data, split, point_index, response_index)
onsets = failure_data.onset_step(:,point_index,response_index);
admissible = build_admissible_mask(dataset.step, dataset.sim_id, onsets);
dev = admissible & ismember(dataset.sim_id, split.development_ids);
test = admissible & ismember(dataset.sim_id, split.test_ids);
data.X_development=dataset.X(dev,:); data.y_development=dataset.Y(dev,point_index,response_index);
data.X_test=dataset.X(test,:); data.y_test=dataset.Y(test,point_index,response_index);
data.development_rows=find(dev); data.test_rows=find(test);
data.development_sim_ids=dataset.sim_id(dev); data.test_sim_ids=dataset.sim_id(test);
data.development_step=dataset.step(dev); data.test_step=dataset.step(test);
assert(isempty(intersect(unique(dataset.sim_id(dev)), unique(dataset.sim_id(test)))));
end
