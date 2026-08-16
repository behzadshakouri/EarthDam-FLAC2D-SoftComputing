function diagnostics = diagnose_difficult_case_histories(results_dir, methods)
%DIAGNOSE_DIFFICULT_CASE_HISTORIES Diagnose held-out difficult cases.
% Reads saved predictions only; no model is retrained. Metrics are computed
% separately for every held-out realization, and best/median/worst histories
% (ranked by nRMSE) are plotted for each requested method and case.

root = setup_task2;
cfg = task2_config(root);
if nargin < 1 || isempty(results_dir), results_dir = cfg.results_dir; end
if nargin < 2 || isempty(methods), methods = {'ELM','ELMIGWO'}; end
if ischar(methods) || isstring(methods), methods = cellstr(methods); end

cases = [7 5; 9 3; 10 4; 10 6; 10 7];
out_dir = fullfile(results_dir, 'difficult_case_diagnostics');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
diagnostics = table();

for im = 1:numel(methods)
    method = upper(char(methods{im}));
    for ic = 1:size(cases,1)
        p = cases(ic,1); r = cases(ic,2);
        case_file = locate_checkpoint(root, results_dir, method, p, r);
        if isempty(case_file)
            warning('No %s P%d-R%d checkpoint was found below %s.', ...
                method,p,r,fullfile(root,'results'));
            continue;
        end

        S = load(case_file, 'case_result');
        cr = S.case_result;
        required = {'y_test','y_pred','test_sim_ids','test_step'};
        for k = 1:numel(required)
            assert(isfield(cr, required{k}), ...
                'Checkpoint %s lacks %s. It must be generated with save_predictions=true.', ...
                case_file, required{k});
        end

        y = double(cr.y_test(:));
        yp = double(cr.y_pred(:));
        sim = double(cr.test_sim_ids(:));
        step = double(cr.test_step(:));
        ids = unique(sim, 'stable');
        case_rows = table();

        for j = 1:numel(ids)
            v = sim == ids(j);
            [~,ord] = sort(step(v));
            yj = y(v); yj = yj(ord);
            pj = yp(v); pj = pj(ord);
            sj = step(v); sj = sj(ord);
            mj = calculate_regression_metrics(yj, pj);

            [target_peak, it] = max(yj);
            [pred_peak, ip] = max(pj);
            target_range = max(yj)-min(yj);
            target_std = std(yj,0);
            peak_amplitude_error = pred_peak-target_peak;
            if abs(target_peak) > eps(max(1,abs(target_peak)))
                peak_amplitude_error_pct = 100*peak_amplitude_error/abs(target_peak);
            else
                peak_amplitude_error_pct = NaN;
            end
            peak_time_error_s = (sj(ip)-sj(it))*cfg.time_step_s;
            mean_bias = mean(pj-yj);
            rmse = sqrt(mean((pj-yj).^2));

            row = table(string(method),p,r,ids(j),numel(yj),mj.R2, ...
                mj.nRMSE,mj.nMAE,mj.a10,min(yj),max(yj),target_range, ...
                target_std,mean_bias,rmse,target_peak,pred_peak, ...
                peak_amplitude_error,peak_amplitude_error_pct, ...
                sj(it)*cfg.time_step_s,sj(ip)*cfg.time_step_s, ...
                peak_time_error_s, ...
                'VariableNames',{'model','point','response','simulation_id', ...
                'n','R2','nRMSE','nMAE','a10','target_min','target_max', ...
                'target_range','target_std','mean_bias','RMSE', ...
                'target_peak','predicted_peak','peak_amplitude_error', ...
                'peak_amplitude_error_pct','target_peak_time_s', ...
                'predicted_peak_time_s','peak_time_error_s'});
            case_rows = [case_rows; row]; %#ok<AGROW>
        end

        diagnostics = [diagnostics; case_rows]; %#ok<AGROW>
        writetable(case_rows, fullfile(out_dir, ...
            sprintf('%s_P%d_R%d_by_realization.csv',method,p,r)));
        plot_representative_histories(cr, case_rows, cfg, out_dir);
    end
end

if isempty(diagnostics)
    error('Task2:NoDiagnosticCheckpoints', ...
        ['No matching checkpoints were found. Run method_neuron_sweep or ', ...
         'pass a directory containing saved case_result MAT files.']);
end

diagnostics = sortrows(diagnostics, ...
    {'model','point','response','simulation_id'});
writetable(diagnostics, fullfile(out_dir, ...
    'difficult_cases_by_realization.csv'));
save(fullfile(out_dir,'difficult_cases_by_realization.mat'), ...
    'diagnostics','cases','methods','results_dir','-v7.3');

summary = groupsummary(diagnostics,{'model','point','response'}, ...
    {'mean','median','min','max'}, ...
    {'R2','nRMSE','nMAE','a10','target_range','target_std', ...
     'mean_bias','peak_amplitude_error_pct','peak_time_error_s'});
writetable(summary,fullfile(out_dir,'difficult_cases_diagnostic_summary.csv'));
disp(summary);
fprintf('\nDiagnostics written to:\n%s\n',out_dir);
end

function case_file = locate_checkpoint(root, requested_dir, method, p, r)
name = sprintf('P%d_R%d.mat',p,r);
if strcmpi(method,'ELM'), expected_neurons=30; experiment='ELM_N030';
else, expected_neurons=5; experiment='ELMIGWO_N005'; end

% Prefer the explicitly requested directory, then the controlled neuron
% sweep that produced the selected configurations, then final production.
candidates = { ...
    fullfile(requested_dir,method,name), ...
    fullfile(requested_dir,name), ...
    fullfile(root,'results','method_neuron_sweep',experiment,method,name), ...
    fullfile(root,'results','final_production',method,name)};
if strcmpi(method,'ELM')
    candidates{end+1}=fullfile(root,'results', ...
        'elm_difficult_cases_sampling_sweep','ELM_N030_PGACAP_010', ...
        method,name);
end
for i=1:numel(candidates)
    if checkpoint_matches(candidates{i},method,expected_neurons)
        case_file=candidates{i};
        fprintf('Using checkpoint: %s\n',case_file);
        return;
    end
end

% Last resort: recursively search the results tree, but accept a checkpoint
% only when its recorded method and selected neuron count match.
d=dir(fullfile(root,'results','**',name));
for i=1:numel(d)
    candidate=fullfile(d(i).folder,d(i).name);
    if checkpoint_matches(candidate,method,expected_neurons)
        case_file=candidate;
        fprintf('Using discovered checkpoint: %s\n',case_file);
        return;
    end
end
case_file='';
end

function tf = checkpoint_matches(path,method,expected_neurons)
tf=false;
if exist(path,'file')~=2, return; end
try
    S=load(path,'case_result'); cr=S.case_result;
    saved_method='';
    if isfield(cr,'method'), saved_method=char(cr.method); end
    saved_neurons=[];
    if isfield(cr,'hidden_neurons'), saved_neurons=double(cr.hidden_neurons); end
    tf=strcmpi(saved_method,method) && ...
        ~isempty(saved_neurons) && saved_neurons==expected_neurons;
catch
    tf=false;
end
end

function plot_representative_histories(cr, rows, cfg, out_dir)
% Rank by nRMSE because realization-level R2 is unstable for nearly
% constant histories.
[~,order] = sort(rows.nRMSE,'ascend','MissingPlacement','last');
valid = order(isfinite(rows.nRMSE(order)));
if isempty(valid), return; end
pick = unique([valid(1); valid(round((numel(valid)+1)/2)); valid(end)],'stable');
labels = {'Best','Median','Worst'};

f = figure('Visible','off','Color','w','Position',[100 100 1050 760]);
for k = 1:numel(pick)
    row = rows(pick(k),:);
    v = double(cr.test_sim_ids(:)) == row.simulation_id;
    st = double(cr.test_step(v));
    yt = double(cr.y_test(v));
    yp = double(cr.y_pred(v));
    [st,ord] = sort(st); yt = yt(ord); yp = yp(ord);

    subplot(3,1,k);
    plot(st*cfg.time_step_s,yt,'k-','LineWidth',1.15); hold on;
    plot(st*cfg.time_step_s,yp,'r--','LineWidth',1.05);
    grid on; box on;
    ylabel('Response');
    title(sprintf('%s: simulation %d, R^2=%.3f, nRMSE=%.3f, peak-time error=%.3f s', ...
        labels{min(k,numel(labels))},row.simulation_id,row.R2,row.nRMSE, ...
        row.peak_time_error_s));
    if k == 1, legend('FLAC2D','Prediction','Location','best'); end
end
xlabel('Time (s)');
sgtitle(sprintf('%s P%d-R%d: held-out realization histories', ...
    char(rows.model(1)),rows.point(1),rows.response(1)));
name = sprintf('%s_P%d_R%d_representative_histories.png', ...
    char(rows.model(1)),rows.point(1),rows.response(1));
print(f,fullfile(out_dir,name),'-dpng','-r300');
close(f);
end
