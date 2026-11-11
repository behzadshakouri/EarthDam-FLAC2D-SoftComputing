function metadata = build_task4_metadata(cfg)
%BUILD_TASK4_METADATA Encode only the confirmed scale-block organization.
simulation_id = (1:cfg.num_simulations)';
scale_factor = [repmat(0.25,150,1); repmat(0.50,150,1); repmat(1.50,150,1)];
within_scale_id = repmat((1:150)',3,1);
scale_block = [repmat(1,150,1); repmat(2,150,1); repmat(3,150,1)];
metadata = table(simulation_id,scale_factor,within_scale_id,scale_block);
assert(height(metadata)==450 && all(groupcounts(metadata.scale_factor)==150));
end
