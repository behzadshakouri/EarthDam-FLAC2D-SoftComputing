function cfg = task1_config(root)
%TASK1_CONFIG Single source of truth for the published Task 1 workflow.
if nargin<1 || isempty(root), root=fileparts(fileparts(mfilename('fullpath'))); end
cfg.root=root;
cfg.seed=20260827;
cfg.num_realizations=500;
cfg.input_count=18;
cfg.num_points=10;
cfg.num_responses=4;
cfg.sample_sizes=[50 100 150 200 300 400 500];
cfg.development_fraction=0.70;
cfg.paper_selected_sample_size=200;
cfg.paper_selected_development_count=140;
cfg.paper_selected_test_count=60;
cfg.scaling_range=[-1 1];
cfg.activation='sigmoid';
% Provenance only: the original study used 100 historical trials to select
% activation/hidden-neuron settings. Canonical production uses the selected
% counts preserved below; it does not repeat that undocumented random search.
cfg.historical_configuration_trials=100;
cfg.methods={'ELM','ELMABC','ELMACOR','ELMIGWO'};
cfg.response_names={'Xdisp','Ydisp','Sxx','Syy'};
cfg.response_symbols={'delta_x','delta_y','sigma_xx','sigma_yy'};
cfg.qoi_grid_rows=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];
cfg.output_columns=[3 4 5 6];
cfg.raw=task1_user_paths(root);
cfg.data_dir=fullfile(root,'data');
cfg.results_dir=fullfile(root,'results','final_production');
cfg.production.resume=true;
cfg.production.ridge=1e-4;
cfg.production.response_hidden_neurons=struct( ...
    'ELM',16,'ELMABC',2,'ELMACOR',3,'ELMIGWO',14);
cfg.production.fos_hidden_neurons=struct( ...
    'ELM',20,'ELMABC',2,'ELMACOR',2,'ELMIGWO',14);
cfg.production.bound_min=-1; cfg.production.bound_max=1;
cfg.abc.max_iter=1000; cfg.abc.pop_size=30;
cfg.abc.onlooker_count=20; cfg.abc.max_acceleration=0.4;
cfg.acor.max_iter=1000; cfg.acor.pop_size=40;
cfg.acor.sample_count=40; cfg.acor.q=0.1; cfg.acor.zeta=1.0;
cfg.igwo.max_iter=1000; cfg.igwo.pop_size=30;
if exist('task1_user_settings','file')==2, cfg=task1_user_settings(cfg); end
assert(cfg.num_points*cfg.num_responses==40);
assert(cfg.paper_selected_development_count+cfg.paper_selected_test_count==200);
assert(isequal(cfg.scaling_range,[-1 1]) && strcmpi(cfg.activation,'sigmoid'));
end
