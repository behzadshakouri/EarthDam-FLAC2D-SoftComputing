function [results, report] = rebuild_all_four_method_aggregates(results_dir)
%REBUILD_ALL_FOUR_METHOD_AGGREGATES Rebuild aggregates from case checkpoints.
% No model is rerun. P#_R#.mat checkpoints are authoritative, so staged runs
% cannot overwrite rows produced by earlier model calls.
root = setup_task2;
cfg = task2_config(root);
if exist('task2_user_settings','file') == 2, cfg = task2_user_settings(cfg); end
if nargin < 1 || isempty(results_dir), results_dir = cfg.results_dir; end
results_dir = char(results_dir);
methods = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
vars = {'model','point','response','hidden_neurons','n_test','R2','nRMSE','nMAE','a10', ...
    'a10_eligible','constant_reference','train_s'};
if ~exist(cfg.split_file,'file')
    error('Task2:MissingSplit','Split file not found: %s',cfg.split_file);
end
S = load(cfg.split_file,'split'); split = S.split;
results = table();
case_files = table(strings(0,1),zeros(0,1),zeros(0,1),strings(0,1), ...
    'VariableNames',{'model','point','response','case_file'});
results_by_method = struct();
complete = false(numel(methods),1);
for im = 1:numel(methods)
    method = methods{im};
    rows = table();
    index = table(strings(0,1),zeros(0,1),zeros(0,1),strings(0,1), ...
        'VariableNames',{'model','point','response','case_file'});
    missing = strings(0,1);
    for p = 1:cfg.num_points
        for r = 1:cfg.num_responses
            caseName = sprintf('P%d_R%d',p,r);
            caseFile = fullfile(results_dir,method,[caseName '.mat']);
            if ~exist(caseFile,'file')
                missing(end+1,1) = string(caseName); %#ok<AGROW>
                continue
            end
            A = load(caseFile,'case_result');
            if ~isfield(A,'case_result'), error('Task2:InvalidCheckpoint','case_result missing: %s',caseFile); end
            cr = A.case_result;
            if cr.point~=p || cr.response~=r || ~strcmpi(char(string(cr.method)),method)
                error('Task2:CheckpointMismatch','Checkpoint identity mismatch: %s',caseFile);
            end
            row = cr.metrics;
            if ~istable(row) || height(row)~=1, error('Task2:InvalidMetrics','Invalid metrics: %s',caseFile); end
            if ~ismember('hidden_neurons',row.Properties.VariableNames)
                if isfield(cr,'hidden_neurons')
                    row.hidden_neurons=double(cr.hidden_neurons);
                elseif isfield(cr,'model')&&isstruct(cr.model)&&isfield(cr.model,'hidden_neurons')
                    row.hidden_neurons=double(cr.model.hidden_neurons);
                else
                    error('Task2:MissingNeuronMetadata','No neuron count in %s',caseFile);
                end
            end
            absent = setdiff(vars,row.Properties.VariableNames);
            if ~isempty(absent), error('Task2:InvalidMetrics','Missing metrics in %s: %s',caseFile,strjoin(absent,', ')); end
            row = row(:,vars); row.model=string(method); row.point=p; row.response=r;
            if isempty(rows),rows=row;else,rows=[rows;row];end %#ok<AGROW>
            q = table(string(method),p,r,string(fullfile(method,[caseName '.mat'])), ...
                'VariableNames',{'model','point','response','case_file'});
            index = [index;q]; %#ok<AGROW>
        end
    end
    rows=sortrows(rows,{'point','response'}); index=sortrows(index,{'point','response'});
    complete(im)=isempty(missing); results_by_method.(method)=rows;
    if ~isempty(rows)
        if isempty(results),results=rows;else,results=[results;rows];end %#ok<AGROW>
    end
    case_files=[case_files;index]; %#ok<AGROW>
    writetable(rows,fullfile(results_dir,sprintf('task2_%s_metrics.csv',lower(method))));
    payload=struct('cfg',cfg,'split',split,'results',rows,'method',method, ...
        'case_files',index,'missing_cases',missing,'source_directory', ...
        fullfile(results_dir,method));
    save(fullfile(results_dir,sprintf('task2_%s_results.mat',lower(method))), ...
        '-struct','payload','-v7.3');
end
if ~isempty(results)
    results.aggregate_order=categorical(results.model,string(methods),'Ordinal',true);
    results=sortrows(results,{'aggregate_order','point','response'}); results.aggregate_order=[];
end
if ~isempty(case_files)
    case_files.aggregate_order=categorical(case_files.model,string(methods),'Ordinal',true);
    case_files=sortrows(case_files,{'aggregate_order','point','response'}); case_files.aggregate_order=[];
end
report=table(string(methods(:)),zeros(numel(methods),1),complete, ...
    'VariableNames',{'model','case_count','complete'});
for im=1:numel(methods), report.case_count(im)=height(results_by_method.(methods{im})); end
generated_on=datetime('now','TimeZone','UTC'); %#ok<NASGU>
writetable(results,fullfile(results_dir,'task2_all_model_metrics.csv'));
save(fullfile(results_dir,'task2_all_model_results.mat'),'results','results_by_method', ...
    'case_files','report','methods','cfg','split','generated_on','-v7.3');
writetable(results,fullfile(results_dir,'task2_all_four_methods_metrics.csv'));
save(fullfile(results_dir,'task2_all_four_methods_results.mat'),'results','results_by_method', ...
    'case_files','report','methods','cfg','split','generated_on','-v7.3');
fprintf('\nAggregate checkpoint inventory:\n'); disp(report);
fprintf('Combined rows written: %d (maximum 280).\n',height(results));
end
