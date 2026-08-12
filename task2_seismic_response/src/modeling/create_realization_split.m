function split = create_realization_split(cfg)
rng(cfg.seed, 'twister'); ids = randperm(cfg.num_realizations);
split = struct('schema_name','task2_realization_split','seed',cfg.seed, ...
 'development_ids',sort(ids(1:cfg.development_count))', ...
 'test_ids',sort(ids(cfg.development_count+1:end))');
assert(isempty(intersect(split.development_ids, split.test_ids)));
end
