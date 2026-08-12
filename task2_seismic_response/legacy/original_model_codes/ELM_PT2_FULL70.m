% ============================================================
% ELM_PT2_FULL70.m
% FULL 70 cases, PT2 style (ELM)
% Same structure + exports as your FULL70 template.
% NOTE: Metaheuristics optimize ONLY Win & b; output weights via ridge.
% ============================================================

clc
clear all %#ok
close all

% LOAD FULL MAT
FULL_file = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\Data\FULL_ALL_POINTS_ALL_RESPONSES_XY.mat';
S = load(FULL_file);
FULL = S.FULL;

% OUTPUT ROOT
outRoot = 'E:\University\My Thesis\Flac model\New\Maku_PT2_Data\ELM_FULL70_OUT';
if ~exist(outRoot,'dir'), mkdir(outRoot); end

% Window
start_time = 0;
end_time   = 20;

% Failure mode
failure_mode = 'response';   % 'response' | 'point' | 'global'
FAILURE_TIMES_FILE = fullfile('E:\University\My Thesis\Flac model\New\Maku_PT2_Data\Data', 'FAILURE_TIMES_v6.mat');

% reporting-only
failure_limit_default = 1e9;
log_use = 0;
alldata = 0;

% knobs
maxPGAperTemplate = 10;

% ELM knobs
hln = 20;
activationFunction = 'sig';

% Ridge + bounds knobs (NEW)
lambda_ridge = 1e-4;
bound_scale  = 2.0;
bound_cap    = 10;

% Fitness subset speed knob (recommended)
max_fit_samples = 50000;



% constants
nsample = FULL.info.nsample;
sec_num = FULL.info.sec_num;
Points    = FULL.info.Points;
Responses = FULL.info.Responses;

% load FT once
if ~exist(FAILURE_TIMES_FILE,'file')
    error('FAILURE_TIMES file not found: %s', FAILURE_TIMES_FILE);
end
Sft = load(FAILURE_TIMES_FILE);
FT = Sft.FT;

tag_all = datestr(now,'yyyymmdd_HHMMSS');
errlog = {};

for ip = 1:numel(Points)
    P = Points(ip);
    Point = sprintf('P%d', P);

    Xfull = FULL.Point(ip).X;
    Yfull = FULL.Point(ip).Y;
    meta  = FULL.Point(ip).meta;

    inWin = (meta.time_s >= start_time) & (meta.time_s <= end_time);
    Xwin_all = Xfull(inWin,:);
    Ywin_all = Yfull(inWin,:);

    data_num = size(Xwin_all,1);

    fprintf('\n=============================================\n');
    fprintf('Point %s | window [%.2f, %.2f] s | rows=%d\n', Point, start_time, end_time, data_num);
    fprintf('=============================================\n');

    ipFT = find(FT.meta.points == P, 1, 'first');
    if isempty(ipFT), error('Point P%d not found in FT.meta.points.', P); end

    for ir = 1:numel(Responses)
        R = Responses(ir);
        Response = sprintf('R%d', R);

        fprintf('\n--- Running %s%s | failmode=%s ---\n', Point, Response, char(failure_mode));

        try
            all_data = [double(Xwin_all), double(Ywin_all(:,ir))];   % [X1..X16, y]

            % ----- reporting-only detector v4.2 -----
            failure_limit = failure_limit_default;

            resp_col = 17;
            optsFD = struct();
            optsFD.Rnum              = R;
            optsFD.baseline_sec      = 2.0;
            optsFD.smooth_win_steps  = 11;
            optsFD.use_log           = (log_use==1);
            optsFD.limit_mode        = 'p95';
            optsFD.force_fail_on_max = false;
            optsFD.min_exceed_factor = 0.5;
            optsFD.min_signal_abs    = 1e-12;
            optsFD.min_sg_dz         = 1e-12;

            optsFD.small = struct();
            optsFD.small.z_thresh       = 6.0;
            optsFD.small.level_factor   = 50.0;
            optsFD.small.min_hold_steps = 10;
            optsFD.small.trigger_mode   = 'and';
            optsFD.small.baseline_sec   = [];
            optsFD.small.dz_abs_thresh  = 0;

            optsFD.large = struct();
            optsFD.large.level_factor        = 2.5;
            optsFD.large.z_thresh            = 5.0;
            optsFD.large.min_hold_steps      = 5;
            optsFD.large.baseline_sec        = 1.0;
            optsFD.large.jump_only_hold      = 3;
            optsFD.large.jump_lookback_steps = 25;
            optsFD.large.trigger_mode        = 'or';
            optsFD.large.dz_abs_thresh       = 0;

            det_local = detect_failure_per_sim_col17_v4_2(all_data, nsample, sec_num, start_time, end_time, resp_col, optsFD);
            if ~isnan(det_local.global_limit) && isfinite(det_local.global_limit) && det_local.global_limit > 0
                failure_limit = det_local.global_limit;
            end

            % ----- coupled SAFE mask -----
            irFT = find(FT.meta.responses == R, 1, 'first');
            if isempty(irFT), error('Response R%d not found in FT.meta.responses.', R); end

            switch lower(string(failure_mode))
                case "response"
                    step_fail_use  = FT.resp(ipFT, irFT).det.step_fail(:);
                    failed_sim_use = FT.resp(ipFT, irFT).det.failed_sim(:);
                case "point"
                    step_fail_use  = FT.point(ipFT).step_fail(:);
                    failed_sim_use = FT.point(ipFT).failed_sim(:);
                case "global"
                    step_fail_use  = FT.global.step_fail(:);
                    failed_sim_use = FT.global.failed_sim(:);
                otherwise
                    error('Unknown failure_mode="%s".', failure_mode);
            end

            nStepsW = round((end_time-start_time)*sec_num) + 1;
            nStepsW = min(nStepsW, floor(size(all_data,1)/nsample));

            [row_valid, ~] = build_row_valid_from_step_fail_v5(step_fail_use, failed_sim_use, nsample, nStepsW);

            if numel(row_valid) ~= data_num
                m = min(numel(row_valid), data_num);
                row_valid = row_valid(1:m);
                if m < data_num, row_valid(end+1:data_num,1) = true; end
            end

            safe_data = all_data(row_valid,:);
            fprintf('SAFE mask: mode=%s | SAFE rows=%d/%d | failed_sims=%d/%d\n', ...
                string(failure_mode), nnz(row_valid), data_num, nnz(failed_sim_use), nsample);

            % ----- choose training set -----
            if alldata==1
                data_for_training = all_data;
            else
                data_for_training = safe_data;
            end

            % ----- template reduction -----
            Xtr_all = data_for_training(:,1:16);
            Ytr_all = data_for_training(:,17);

            Xbase = Xtr_all(:,1:15);
            pga   = Xtr_all(:,16);

            [~,~,gid] = unique(Xbase, 'rows', 'stable');
            keep = false(size(Ytr_all));

            for g = 1:max(gid)
                idxg = find(gid==g);
                [~, ia] = unique(pga(idxg), 'stable');
                if numel(ia) > maxPGAperTemplate
                    pick = round(linspace(1, numel(ia), maxPGAperTemplate));
                    ia = ia(pick);
                end
                keep(idxg(ia)) = true;
            end

            data_for_training = data_for_training(keep,:);
            fprintf('Reduced training rows: %d -> %d (maxPGAperTemplate=%d)\n', ...
                numel(Ytr_all), sum(keep), maxPGAperTemplate);

            % ----- shuffle + scale -----
            rng(1,'twister');
            drandperm = randperm(size(data_for_training,1));
            data = data_for_training(drandperm,:);

            input  = data(:,1:16);
            target = data(:,17);

            [inputn,is]  = mapminmax(input');
            [targetn,ts] = mapminmax(target');

            inputn  = inputn';
            targetn = targetn';

            ntrain = ceil(size(data,1)*0.7);
            inputtrainn  = inputn(1:ntrain,:);
            inputtestn   = inputn(ntrain+1:end,:);
            targettrainn = targetn(1:ntrain);
            targettestn  = targetn(ntrain+1:end);

            % Fitness subset for speed
            rng(1,'twister');
            ntr = size(inputtrainn,1);
            if ntr > max_fit_samples
                idx_fit = randperm(ntr, max_fit_samples);
            else
                idx_fit = 1:ntr;
            end
            inputtrainn_fit  = inputtrainn(idx_fit,:);
            targettrainn_fit = targettrainn(idx_fit,:);

%% ============================================================
% Plain ELM core (ridge output weights)
% ============================================================
k = size(inputtrainn,2);

elm = ELM('numberOfInputNeurons', k, ...
          'numberOfHiddenNeurons', hln, ...
          'activationFunction', activationFunction);
elm = elm.train(inputtrainn, targettrainn);

Win = elm.inputWeight;
b   = elm.biasOfHiddenNeurons(:);
Htr = elm_hidden_output(inputtrainn, Win, b, activationFunction);
elm.outputWeight = elm_ridge_beta(Htr, targettrainn, lambda_ridge);

%% Train/test predictions
Ptrainn = elm.predict(inputtrainn);
Ptestn  = elm.predict(inputtestn);

Ptrain = mapminmax('reverse', Ptrainn', ts)'; 
Ptest  = mapminmax('reverse', Ptestn',  ts)'; 
Ttrain = mapminmax('reverse', targettrainn', ts)'; 
Ttest  = mapminmax('reverse', targettestn',  ts)'; 

Ptrain = max(0, Ptrain);
Ptest  = max(0, Ptest);
Ttrain = max(0, Ttrain);
Ttest  = max(0, Ttest);

Errortrain = Error1(Ptrain, Ttrain);
Errortest  = Error1(Ptest,  Ttest);

%% ============================================================
% FULL-LENGTH prediction in original order (SAFE rows only)
% ============================================================
X_safe   = all_data(row_valid,1:16);
X_safe_n = mapminmax('apply', X_safe', is)';

yhat_safe_n = elm.predict(X_safe_n);
yhat_safe   = mapminmax('reverse', yhat_safe_n', ts)';
yhat_safe   = max(0, yhat_safe);

y_obs_full  = all_data(:,17);
y_pred_full = nan(data_num,1);
y_pred_full(row_valid) = yhat_safe;
y_obs_full(~row_valid) = nan;

ErrorSafe = Error1(y_pred_full(row_valid), y_obs_full(row_valid));
fprintf('SAFE-only metrics: RMSE=%g, MAE=%g, R2=%g, a10=%g\n', ...
    ErrorSafe.RMSE, ErrorSafe.MAE, ErrorSafe.Corkare, ErrorSafe.a10);

%% Meta columns
row_idx  = (1:data_num)';
sim_id   = mod(row_idx-1, nsample) + 1;
step_idx = floor((row_idx-1)/nsample) + 1;
time_sec = (step_idx-1) ./ sec_num + start_time;

fail_step_sim = nan(nsample,1);
fail_time_sim = nan(nsample,1);
failed_sim    = false(nsample,1);

for s = 1:nsample
    bad_s = (sim_id==s) & (~row_valid);
    if any(bad_s)
        first_row = find(bad_s, 1, 'first');
        fail_step_sim(s) = step_idx(first_row);
        fail_time_sim(s) = time_sec(first_row);
        failed_sim(s) = true;
    end
end

outT = table(row_idx, sim_id, step_idx, time_sec, y_obs_full, y_pred_full, ...
    'VariableNames', {'row','sim_id','step','time_s','y_obs','y_pred'});

summaryT = table((1:nsample)', failed_sim, fail_step_sim, fail_time_sim, ...
    'VariableNames', {'sim_id','failed','fail_step','fail_time_s'});

%% Save outputs (per-case folder)
tag = tag_all;
caseDir = fullfile(outRoot, Point, Response);
if ~exist(caseDir,'dir'), mkdir(caseDir); end

base_name = sprintf('%s%s_%.0fs_nobm_fullpred_%s_failmode_%s', ...
    Point, Response, (end_time-start_time), tag_all, char(failure_mode));

writetable(outT,     fullfile(caseDir, [base_name '_obs_pred.csv']));
writetable(summaryT, fullfile(caseDir, [base_name '_failure_summary.csv']));

save(fullfile(caseDir, [base_name '_obs_pred.mat']), ...
    'outT','summaryT','row_valid','start_time','end_time','nsample','sec_num', ...
    'Errortrain','Errortest','ErrorSafe', ...
    'failure_mode','step_fail_use','failed_sim_use', ...
    'failure_limit','log_use','alldata', ...
    'maxPGAperTemplate','hln','activationFunction', ...
    'lambda_ridge','bound_scale','bound_cap', ...
    'elm','is','ts');

%% Scatter SAFE only (robust export)
y_obs_safe2  = y_obs_full(row_valid);
y_pred_safe2 = y_pred_full(row_valid);
validSafe = isfinite(y_obs_safe2) & isfinite(y_pred_safe2);

plot_every_safe = 5;
idxv = find(validSafe);
idxv = idxv(1:plot_every_safe:end);

if any(validSafe)
    xmin = prctile(y_obs_safe2(validSafe), 0.5);
    xmax = prctile(y_obs_safe2(validSafe), 99.5);
    ymin = prctile(y_pred_safe2(validSafe), 0.5);
    ymax = prctile(y_pred_safe2(validSafe), 99.5);
    lo = min(xmin,ymin); hi = max(xmax,ymax);
    pad = 0.02*(hi-lo+eps); lo=lo-pad; hi=hi+pad;
else
    lo=0; hi=1;
end

fig = figure('Visible','off','Color','w');
set(fig,'Renderer','opengl','RendererMode','manual');
hold on; grid on; box on;
scatter(y_obs_safe2(idxv), y_pred_safe2(idxv), 10, [0 0 1], 'filled');
plot([lo hi],[lo hi],'k--','LineWidth',1.5);
xlim([lo hi]); ylim([lo hi]);
xlabel('Observed'); ylabel('Predicted');
title(sprintf('%s%s Obs vs Pred | SAFE R^2=%.4f | fail=%s', ...
    Point, Response, ErrorSafe.Corkare, string(failure_mode)));
legend({sprintf('SAFE (every %dth)', plot_every_safe), '1:1'}, 'Location','best');

png_path = fullfile(caseDir, [base_name '_obs_vs_pred_scatter.png']);
drawnow;
img = print(fig, '-RGBImage', '-r300');
imwrite(img, png_path);
close(fig);

%% Stats xlsx
stats_xlsx = fullfile(caseDir, sprintf('ELM_%s%s_n%d_Statistics_%s_failmode_%s.xlsx', ...
    Point, Response, size(data,1), tag_all, char(failure_mode)));

A = {'train.R2','train.RMSE','train.MAE','train.a10', ...
     'test.R2','test.RMSE','test.MAE','test.a10', ...
     'safe.R2','safe.RMSE','safe.MAE','safe.a10'; ...
    Errortrain.Corkare,Errortrain.RMSE,Errortrain.MAE,Errortrain.a10, ...
    Errortest.Corkare,Errortest.RMSE,Errortest.MAE,Errortest.a10, ...
    ErrorSafe.Corkare,ErrorSafe.RMSE,ErrorSafe.MAE,ErrorSafe.a10};

xlswrite(stats_xlsx, A, 1, 'A1');

fprintf('Saved: %s\n', fullfile(caseDir, [base_name '_obs_pred.csv']));


        catch ME
            warning('FAILED %s%s: %s', Point, Response, ME.message);
            errlog(end+1,:) = {Point, Response, ME.message}; %#ok<AGROW>
        end
    end
end

if ~isempty(errlog)
    T = cell2table(errlog, 'VariableNames', {'Point','Response','Message'});
    writetable(T, fullfile(outRoot, ['ERROR_LOG_' tag_all '.csv']));
end

disp('ALL 70 CASES DONE.');

%% ============================================================
% Helpers (local)
%% ============================================================
function H = elm_hidden_output(Xn, Win, b, act)
    % Win is [k x hln] (as stored in elm.inputWeight)
    Z = Xn * Win + repmat(b(:).', size(Xn,1), 1);
    switch lower(act)
        case {'sig','sigmoid'}
            H = 1 ./ (1 + exp(-Z));
        case {'tanh'}
            H = tanh(Z);
        otherwise
            error('Unknown activationFunction: %s', act);
    end
end

function beta = elm_ridge_beta(H, Yn, lambda_ridge)
    beta = (H'*H + lambda_ridge*eye(size(H,2))) \ (H'*Yn);
end

function rmse = rmse_elm_ridge(x, Xn, Yn, k, hln, act, lambda_ridge)
    Win = vec2mat(x(1:k*hln), k)';   % [k x hln]
    b   = x(k*hln+1:end);            % [hln x 1]
    H = elm_hidden_output(Xn, Win, b, act);
    beta = elm_ridge_beta(H, Yn, lambda_ridge);
    yhat = H * beta;
    rmse = sqrt(mean((yhat - Yn).^2));
end

function [lb, ub] = scalar_bounds_from_x0(x0, bound_scale, cap)
    m = max(1e-6, max(abs(x0)));
    B = min(cap, bound_scale * m);
    lb = -B; ub = +B;
end
