function report = generate_failure_screening_report()
%GENERATE_FAILURE_SCREENING_REPORT Tables and canonical failure heatmaps.
root=setup_task2;cfg=task2_config(root);
S=load(cfg.failure_file,'failure_data'); F=S.failure_data;
outDir=fullfile(root,'results','failure_screening');
if ~isfolder(outDir),mkdir(outDir);end
rows=table();
for p=1:cfg.num_points
    for r=1:cfg.num_responses
        detected=F.failure_detected(:,p,r);
        times=F.onset_time_s(detected,p,r);
        values=F.onset_value(detected,p,r);
        if isempty(times)
            medianTime=nan; earliestTime=nan; medianValue=nan;
        else
            medianTime=median(times,'omitnan');
            earliestTime=min(times,[],'omitnan');
            medianValue=median(values,'omitnan');
        end
        one=table(p,r,nnz(detected),mean(detected), ...
            medianTime,earliestTime,medianValue, ...
            'VariableNames',{'point','response','detected_histories', ...
            'detected_fraction','median_onset_s','earliest_onset_s', ...
            'median_onset_value'});
        rows=[rows;one]; %#ok<AGROW>
    end
end
report=rows;
writetable(report,fullfile(outDir,'failure_screening_summary.csv'));
write_parameter_table(cfg,fullfile(outDir,'failure_detector_parameters.csv'));
plot_matrix(rows.detected_fraction,'Detected fraction', ...
    fullfile(outDir,'failure_detected_fraction.png'));
plot_matrix(rows.median_onset_s,'Median onset time (s)', ...
    fullfile(outDir,'failure_median_onset_time.png'));
plot_matrix(rows.earliest_onset_s,'Earliest onset time (s)', ...
    fullfile(outDir,'failure_earliest_onset_time.png'));
fprintf('Failure-screening report saved under %s\n',outDir);
end

function write_parameter_table(cfg,path)
r=(1:cfg.num_responses)';
T=table(r,cfg.detector.baseline_s(:),cfg.detector.z_threshold(:), ...
    cfg.detector.level_factor(:),cfg.detector.hold_steps(:), ...
    cfg.detector.logic(:),cfg.detector.jump_only_hold(:), ...
    cfg.detector.jump_lookback_steps(:), ...
    'VariableNames',{'response','baseline_s','z_threshold','level_factor', ...
    'hold_steps','logic','jump_only_hold','jump_lookback_steps'});
writetable(T,path);
end

function plot_matrix(values,titleText,path)
M=reshape(values,7,10)';
f=figure('Visible','off','Color','w','Position',[100 100 1100 650]);
imagesc(M);axis image;colorbar;
xlabel('Response');ylabel('Monitoring point');title(titleText);
xticks(1:7);xticklabels(compose('R%d',1:7));
yticks(1:10);yticklabels(compose('P%d',1:10));
exportgraphics(f,path,'Resolution',220);close(f);
end
