function [historyAudit,caseSummary] = audit_task4_responses(Task4,metadata,cfg)
%AUDIT_TASK4_RESPONSES Audit all 450-by-70 histories without modeling them.
dictionary = task4_response_dictionary();
nRows = cfg.num_simulations*cfg.num_cases;
simulation_id=zeros(nRows,1); scale_factor=zeros(nRows,1); case_id=zeros(nRows,1);
point=zeros(nRows,1); response=zeros(nRows,1); original_length=zeros(nRows,1);
time_length=zeros(nRows,1); clean_length=zeros(nRows,1); first_invalid_index=nan(nRows,1);
was_truncated=false(nRows,1); length_matches_time=false(nRows,1);
is_usable=false(nRows,1); maximum_absolute_clean_value=nan(nRows,1);
label=cell(nRows,1); k=0;
admissible_samples=zeros(nRows,1); onset_time_s=nan(nRows,1);
screening_status=repmat({''},nRows,1); screening_message=screening_status;
removed_nonfinite_pairs=zeros(nRows,1); raw_prefix_usable=false(nRows,1);
padded_tail_samples=zeros(nRows,1);
for i=1:cfg.num_simulations
    if isa(Task4,'function_handle')
        t=Task4('/Task4/Outputs/dytime',i);
    else
        t=Task4.Outputs.dytime{i};
    end
    for c=1:cfg.num_cases
        k=k+1; p=dictionary(c).point; r=dictionary(c).response;
        if isa(Task4,'function_handle')
            history=Task4(sprintf('/Task4/Outputs/P%d/R%d',p,r),i);
        else
            histories=Task4.Outputs.(sprintf('P%d',p)).(sprintf('R%d',r));
            history=histories{i};
        end
        [~,info]=clean_task4_history(history,cfg);
        simulation_id(k)=i; scale_factor(k)=metadata.scale_factor(i); case_id(k)=c;
        point(k)=p; response(k)=r; label{k}=dictionary(c).label;
        original_length(k)=info.original_length; time_length(k)=numel(t);
        clean_length(k)=info.clean_length; was_truncated(k)=info.was_truncated;
        is_usable(k)=info.is_usable; maximum_absolute_clean_value(k)=info.maximum_absolute_clean_value;
        length_matches_time(k)=info.original_length==numel(t);
        if ~isempty(info.first_invalid_index), first_invalid_index(k)=info.first_invalid_index; end
        raw_prefix_usable(k)=info.is_usable;
        is_usable(k)=false;
        try
            [~,~,screen]=prepare_task4_history(t,history,r,cfg);
            removed_nonfinite_pairs(k)=screen.removed_nonfinite_pairs;
            padded_tail_samples(k)=screen.padded_tail_samples;
            admissible_samples(k)=screen.admissible_samples;
            onset_time_s(k)=screen.onset_time_s;
            is_usable(k)=screen.is_usable;
            screening_status{k}='screened';
        catch err
            if ~startsWith(err.identifier,'Task4:')
                rethrow(err);
            end
            screening_status{k}=err.identifier;
            screening_message{k}=err.message;
        end
    end
    if mod(i,25)==0 || i==cfg.num_simulations
        fprintf('Task 4 screening: %d/%d simulations.\n',i,cfg.num_simulations);
    end
end
historyAudit=table(simulation_id,scale_factor,case_id,point,response,label, ...
    original_length,time_length,clean_length,first_invalid_index,was_truncated, ...
    length_matches_time,is_usable,maximum_absolute_clean_value, ...
    raw_prefix_usable,removed_nonfinite_pairs,admissible_samples,onset_time_s, ...
    screening_status,screening_message,padded_tail_samples);
caseSummary=groupsummary(historyAudit,{'scale_factor','case_id','point','response','label'}, ...
    {'sum','min','max'},{'was_truncated','clean_length','maximum_absolute_clean_value', ...
    'is_usable','admissible_samples'});
end
