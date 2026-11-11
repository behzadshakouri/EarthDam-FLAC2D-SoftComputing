function dataset=build_task4_scale_aware_dataset(samplesPerRecord)
%BUILD_TASK4_SCALE_AWARE_DATASET Combine Task 2 and Task 4 response fields.
% The output is record-major on a fixed 20 s grid.  Each response retains
% its own Task 2-style admissibility mask; one failed channel never removes
% otherwise valid targets from the other 69 channels.
if nargin<1, samplesPerRecord=100; end
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_task4;
cfg=task4_config(root); validate_paths(cfg.raw);

task2=load(cfg.raw.task2_data_file,'Task2'); task2=task2.Task2;
rvs4=readmatrix(cfg.raw.task4_rvs_file); water4=readmatrix(cfg.raw.task4_water_level_file);
rvs4=rvs4(:,1:14); water4=water4(:,1);
assert(isequal(size(rvs4),[450 14]) && isequal(size(water4),[450 1]));
inputs2=double(task2.Inputs.InputsMatrix(:,1:15));
assert(isequal(size(inputs2),[300 15]));

scale=[ones(300,1);repmat(.25,150,1);repmat(.50,150,1);repmat(1.50,150,1)];
physical=[inputs2;[rvs4 water4]];
levelRatio=physical(:,15)./(65.92*scale);
recordInputs=[physical scale];
physicalNames=["density_core" "density_shell" "density_filter" "density_drainage" ...
    "modulus_core" "modulus_shell" "modulus_drainage" "modulus_alluvium" ...
    "poisson_core" "cohesion_core" "friction_shell" "friction_filter" ...
    "friction_drainage" "friction_alluvium" "water_level_m"];
[dynamic,dynamicNames]=build_dynamic_features(cfg.raw.ground_motion_file,cfg.time_s);
featureNames=[physicalNames dynamicNames "scale_factor"];

nRecords=750; nRows=nRecords*samplesPerRecord;
X=zeros(nRows,numel(featureNames),'single'); Y=nan(nRows,70,'single');
admissibleRows=false(nRows,70);
recordId=zeros(nRows,1,'uint16'); sourceTask=zeros(nRows,1,'uint8');
scaleRows=zeros(nRows,1,'single'); timeRows=zeros(nRows,1,'single');
commonEnd=zeros(nRecords,1); sentinelRecord=false(nRecords,1);
outputEnd=zeros(nRecords,70);
safePeak=zeros(nRecords,70);
selected=round(linspace(1,numel(cfg.time_s),samplesPerRecord));

[reader,cleanup]=open_task4_history_reader(cfg.raw.task4_data_file,cfg);
for id=1:nRecords
    if id<=300
        local=id; time=double(task2.Outputs.dytime{local}(:));
    else
        local=id-300; time=reader('/Task4/Outputs/dytime',local);
    end
    responseField=nan(numel(cfg.time_s),70); responseMask=false(numel(cfg.time_s),70);
    common=true(numel(cfg.time_s),1);
    for p=1:10
        for r=1:7
            col=(p-1)*7+r;
            if id<=300
                raw=double(task2.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r)){local}(:));
            else
                raw=reader(sprintf('/Task4/Outputs/P%d/R%d',p,r),local);
            end
            sentinelRecord(id)=sentinelRecord(id) || any(isfinite(raw) & abs(raw)>=cfg.sentinel_abs_threshold);
            [envelope,admissible]=prepare_task4_history_native(time,raw,r,cfg);
            responseField(:,col)=envelope; responseMask(:,col)=admissible;
            common=common & admissible;
            lastOutput=find(admissible,1,'last');
            if ~isempty(lastOutput)
                outputEnd(id,col)=cfg.time_s(lastOutput);
                safePeak(id,col)=envelope(lastOutput);
            end
        end
    end
    last=find(common,1,'last');
    if isempty(last) || last<cfg.minimum_clean_samples
        error('Task4:NoCommonDomain','Record %d has no common admissible interval.',id);
    end
    first=find(common,1,'first');
    if first~=1 || any(~common(first:last))
        error('Task4:NoncontiguousDomain', ...
            'Record %d does not have a contiguous common prefix.',id);
    end
    rows=(id-1)*samplesPerRecord+(1:samplesPerRecord);
    X(rows,:)=[repmat(single(physical(id,:)),samplesPerRecord,1) ...
        single(dynamic(selected,:)) repmat(single(scale(id)),samplesPerRecord,1)];
    selectedMask=responseMask(selected,:);
    selectedY=single(responseField(selected,:)); selectedY(~selectedMask)=nan;
    Y(rows,:)=selectedY; admissibleRows(rows,:)=selectedMask; recordId(rows)=id;
    sourceTask(rows)=uint8(2+(id>300)*2); scaleRows(rows)=single(scale(id));
    timeRows(rows)=single(cfg.time_s(selected)); commonEnd(id)=cfg.time_s(last);
    if mod(id,25)==0, fprintf('Scale-aware preparation: %d/%d records.\n',id,nRecords); end
end
clear cleanup;
assert(all(isfinite(X(:))) && all(isfinite(Y(admissibleRows))) && ...
    all(Y(admissibleRows)>=0) && all(isnan(Y(~admissibleRows))));
metadata=table((1:nRecords)',[repmat("Task2",300,1);repmat("Task4",450,1)], ...
    scale,physical(:,15),levelRatio,commonEnd,sentinelRecord, ...
    'VariableNames',{'record_id','source','scale_factor','water_level_m', ...
    'relative_water_level','common_end_time_s','had_sentinel'});
dictionary=task4_response_dictionary();
dataset=struct('X',X,'Y',Y,'record_id',recordId,'source_task',sourceTask, ...
    'scale_factor',scaleRows,'time_s',timeRows,'feature_names',featureNames, ...
    'output_dictionary',dictionary,'metadata',metadata, ...
    'admissible',admissibleRows,'output_end_time_s',outputEnd, ...
    'record_features',single(recordInputs), ...
    'record_feature_names',[physicalNames "scale_factor"], ...
    'safe_peak_targets',safePeak, ...
    'samples_per_record',samplesPerRecord,'row_order','record-major');
out=fullfile(cfg.results_dir,'scale_aware'); if ~exist(out,'dir'), mkdir(out); end
save(fullfile(out,'task4_scale_aware_dataset.mat'),'dataset','-v7.3');
writetable(metadata,fullfile(out,'task4_scale_aware_metadata.csv'));
end

function validate_paths(paths)
names={'task4_data_file','task2_data_file','task4_rvs_file','task4_water_level_file','ground_motion_file'};
for i=1:numel(names)
    assert(isfield(paths,names{i}) && isfile(paths.(names{i})),'Missing private input: %s',names{i});
end
end

function [dynamic,names]=build_dynamic_features(file,time)
raw=readmatrix(file,'FileType','text','NumHeaderLines',2); raw=raw(isfinite(raw)); raw=raw(:);
assert(numel(raw)>=numel(time)); a=double(raw(1:numel(time))); g=9.807;
t=double(time(:)); %#ok<NASGU>
dynamic=cummax(abs(a));
names="running_PGA_g";
end
