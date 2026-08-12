function paths = save_full_predictions_time_major(out_dir, base_name, all_data, nsample, sec_num, start_time, row_valid, yhat_safe, resp_col)
% Save full time-major predictions aligned to the ORIGINAL (unshuffled) all_data row order.
%
% all_data   : [nRows x nCols] time-major (step1 sims1..N, step2 sims1..N, ...)
% row_valid  : [nRows x 1] logical, true where prediction is valid (safe)
% yhat_safe  : [nnz(row_valid) x 1] predictions for safe rows, in the SAME order as all_data(row_valid,:)
% resp_col   : scalar, which column is the true response (e.g., 17)
%
% Outputs:
%  - MAT bundle with t_full, step_id, sim_id, y_true, yhat_full (NaN unsafe), status, etc.
%  - optional CSV

    if nargin < 9 || isempty(resp_col)
        resp_col = size(all_data,2);
    end

    nRows = size(all_data,1);
    if numel(row_valid) ~= nRows
        error('row_valid length (%d) != nRows (%d).', numel(row_valid), nRows);
    end

    % Build identifiers (time-major)
    nSteps = floor(nRows / nsample);
    nUse = nSteps * nsample;
    if nUse ~= nRows
        % trim to full steps
        all_data = all_data(1:nUse,:);
        row_valid = row_valid(1:nUse);
        nRows = nUse;
    end

    step_id = repelem((1:nSteps)', nsample, 1);
    sim_id  = repmat((1:nsample)', nSteps, 1);
    t_full  = start_time + (step_id-1)/sec_num;

    y_true = all_data(:, resp_col);

    yhat_full = nan(nRows,1);
    if numel(yhat_safe) ~= nnz(row_valid)
        error('yhat_safe length (%d) != nnz(row_valid) (%d).', numel(yhat_safe), nnz(row_valid));
    end
    yhat_full(row_valid) = yhat_safe;

    status = zeros(nRows,1,'uint8'); % 0 unsafe, 1 safe/predicted
    status(row_valid) = 1;

    if ~exist(out_dir,'dir'), mkdir(out_dir); end

    mat_path = fullfile(out_dir, [base_name '_fullpred_time_major.mat']);
    save(mat_path, 't_full','step_id','sim_id','y_true','yhat_full','status','row_valid', ...
         'nsample','sec_num','start_time','resp_col','-v7.3');

    csv_path = fullfile(out_dir, [base_name '_fullpred_time_major.csv']);
    try
        T = table(t_full, step_id, sim_id, y_true, yhat_full, status);
        writetable(T, csv_path);
    catch
        csv_path = '';
    end

    paths.mat = mat_path;
    paths.csv = csv_path;
end
