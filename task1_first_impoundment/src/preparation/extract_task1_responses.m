function Y = extract_task1_responses(outputs_gp,cfg)
%EXTRACT_TASK1_RESPONSES Return 500 x 10 x 4 scalar response array.
Y=zeros(cfg.num_realizations,cfg.num_points,cfg.num_responses);
for p=1:cfg.num_points
    for r=1:cfg.num_responses
        Y(:,p,r)=reshape(outputs_gp(cfg.qoi_grid_rows(p),cfg.output_columns(r),:),[],1);
    end
end
assert(all(isfinite(Y(:))),'Task1:NonfiniteTargets','Extracted targets are nonfinite.');
end
