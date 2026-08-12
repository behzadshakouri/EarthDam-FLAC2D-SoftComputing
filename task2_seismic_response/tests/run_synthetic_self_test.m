function run_synthetic_self_test()
root=setup_task2; cfg=task2_config(root);
cfg.num_realizations=12; cfg.development_count=8; cfg.test_count=4; cfg.num_time_steps=20;
cfg.time_s=(1:20)'*cfg.time_step_s; cfg.input_count=3; cfg.num_points=2; cfg.num_responses=2;
meta=build_row_metadata(cfg); n=numel(meta.step); rng(7);
X=randn(n,3); Y=zeros(n,2,2);
for p=1:2, for r=1:2, Y(:,p,r)=cummax(abs(0.2*X(:,1)+0.1*p+0.05*r)); end,end
dataset=assemble_consolidated_dataset(X,Y,cfg); validate_consolidated_dataset(dataset,cfg);
env=build_response_envelope([-1;2;-0.5;3]); assert(isequal(env,[1;2;2;3]));
split=create_realization_split(cfg); assert(numel(split.development_ids)==8 && numel(split.test_ids)==4);
model=train_elm(X(1:150,:),Y(1:150,1,1),cfg.elm,1); pred=predict_elm(model,X(151:end,:));
m=calculate_regression_metrics(Y(151:end,1,1),pred); assert(m.n==n-150);
fprintf('Synthetic self-test passed. Canonical times: %.2f to %.2f s.\n',dataset.time_s(1),dataset.time_s(end));
end
