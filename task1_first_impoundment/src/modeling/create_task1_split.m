function split = create_task1_split(n,development_fraction,seed)
%CREATE_TASK1_SPLIT Reproducible realization-level 70/30 split.
rng(seed,'twister'); order=randperm(n);
ndev=ceil(n*development_fraction);
split.development=order(1:ndev);
split.test=order(ndev+1:end);
split.seed=seed; split.n=n;
end
