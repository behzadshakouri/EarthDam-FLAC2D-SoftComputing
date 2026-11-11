function split = create_task3_split(cfg)
%CREATE_TASK3_SPLIT Fixed realization-level 105/45 partition.
rng(cfg.seed, 'twister'); order = randperm(cfg.num_realizations);
split.development_ids = sort(order(1:cfg.development_count))';
split.test_ids = sort(order(cfg.development_count+1:end))';
assert(isempty(intersect(split.development_ids,split.test_ids)));
assert(numel(union(split.development_ids,split.test_ids)) == cfg.num_realizations);
end
