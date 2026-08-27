function run_synthetic_self_test()
%RUN_SYNTHETIC_SELF_TEST Tests extraction, splitting and metrics without data.
root=setup_task1; cfg=task1_config(root);
A=zeros(28392,6,500);
for p=1:10
    for r=1:4, A(cfg.qoi_grid_rows(p),cfg.output_columns(r),:)=p+r; end
end
Y=extract_task1_responses(A,cfg);
assert(isequal(size(Y),[500 10 4]) && Y(1,10,4)==14);
s=create_task1_split(200,0.70,cfg.seed);
assert(numel(s.development)==140 && numel(s.test)==60 && ...
    isempty(intersect(s.development,s.test)));
M=calculate_task1_metrics((1:10)',(1:10)');
assert(abs(M.R2-1)<1e-12 && M.RMSE==0 && M.MAE==0 && M.a10==1);
fprintf('Task 1 synthetic self-test passed.\n');
end
