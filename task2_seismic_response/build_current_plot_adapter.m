function [FT_file,FULL_file] = build_current_plot_adapter(outDir)
%BUILD_CURRENT_PLOT_ADAPTER Map current Task 2 data to author plot inputs.
root=setup_task2; cfg=task2_config(root);
assert(isfile(cfg.failure_file),'Missing %s',cfg.failure_file);
assert(isfile(cfg.consolidated_file),'Missing %s',cfg.consolidated_file);
if nargin<1||isempty(outDir)
    outDir=fullfile(root,'results','final_manuscript_figures','plot_adapter');
end
if ~isfolder(outDir),mkdir(outDir);end

Sf=load(cfg.failure_file,'failure_data'); F=Sf.failure_data;
Sd=load(cfg.consolidated_file,'dataset'); D=Sd.dataset;
assert(isequal(size(F.failure_detected), ...
    [cfg.num_realizations cfg.num_points cfg.num_responses]));
assert(size(D.X,1)==cfg.num_realizations*cfg.num_time_steps && size(D.X,2)>=16);

FT=struct();
FT.meta.nsample=cfg.num_realizations;
FT.meta.sec_num=1/cfg.time_step_s;
FT.meta.start_time=cfg.time_step_s;
FT.meta.source_failure_file=cfg.failure_file;
if isfield(F,'schema_name'), FT.meta.source_schema=F.schema_name;
else, FT.meta.source_schema='task2_failure_database'; end
for p=1:cfg.num_points
    for r=1:cfg.num_responses
        det.failed_sim=logical(F.failure_detected(:,p,r));
        det.step_fail=double(F.onset_step(:,p,r));
        det.fail_time=double(F.onset_time_s(:,p,r));
        det.step_fail(~det.failed_sim)=NaN;
        det.fail_time(~det.failed_sim)=NaN;
        FT.resp(p,r).det=det; %#ok<AGROW>
    end
end

% Original transition plots use only column 16. A sparse bridge preserves
% the canonical time-major row order without duplicating unused columns.
pga=double(D.X(:,16)); n=numel(pga); nz=find(pga~=0 & isfinite(pga));
Xbridge=sparse(nz,16*ones(numel(nz),1),pga(nz),n,16);
FULL=struct();
for p=1:cfg.num_points, FULL.Point(p).X=Xbridge; end
FULL.meta.source_consolidated_file=cfg.consolidated_file;
if isfield(D,'schema_name'), FULL.meta.source_schema=D.schema_name;
else, FULL.meta.source_schema='task2_consolidated_dataset'; end
FULL.meta.row_order='time-major; realization varies fastest';

FT_file=fullfile(outDir,'CURRENT_task2_transition_adapter.mat');
FULL_file=fullfile(outDir,'CURRENT_task2_pga_adapter.mat');
save(FT_file,'FT','-v7.3');
save(FULL_file,'FULL','-v7.3');
fprintf('Current Task 2 plot adapter written to:\n%s\n',outDir);
end
