function validate_task3_dataset(dataset, cfg)
%VALIDATE_TASK3_DATASET Enforce the canonical Task 3 data contract.
assert(isequal(size(dataset.X,1),cfg.num_realizations));
assert(isequal(size(dataset.Y),[cfg.num_realizations cfg.num_outputs]));
assert(size(dataset.X,2) == numel(dataset.feature_names));
assert(all(isfinite(dataset.X(:))), 'Input matrix contains invalid values.');
assert(all(isfinite(dataset.Y(:))), 'Output matrix contains invalid values after QC.');
assert(numel(dataset.output_dictionary) == cfg.num_outputs);
labels = {dataset.output_dictionary.label};
assert(strcmp(labels{1},'P1R1') && strcmp(labels{70},'P10R7'));
end
