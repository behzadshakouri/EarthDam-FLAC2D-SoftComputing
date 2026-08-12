function paths = save_full_predictions_block_major(out_dir, base_name, nsample, sec_num, start_time, block_steps, safe_mask_block_sim, yhat_safe_bm, y_true_bm)
% Save full BLOCK-major predictions aligned to block timeline:
% block1 sims1..N, block2 sims1..N, ...
%
% safe_mask_block_sim : [nBlocks x nsample] logical for which block/sim is safe (predicted)
% yhat_safe_bm        : [nnz(safe_mask_block_sim) x 1] predictions in the order produced by flattening block-major
% y_true_bm           : optional full block-major truth [nBlocks*nsample x 1] (can be [])

    if ~exist(out_dir,'dir'), mkdir(out_dir); end
    if nargin < 9, y_true_bm = []; end

    [nBlocks, ns] = size(safe_mask_block_sim);
    if ns ~= nsample
        error('nsample mismatch: mask has %d, nsample=%d', ns, nsample);
    end

    % identifiers
    block_id = repelem((1:nBlocks)', nsample, 1);
    sim_id   = repmat((1:nsample)', nBlocks, 1);

    dt = 1/sec_num;
    t_block = start_time + ((block_id-1)*block_steps)*dt; % block start time

    nRows = nBlocks*nsample;
    safe_flat = reshape(safe_mask_block_sim', [nRows, 1]); % block-major flatten

    if numel(yhat_safe_bm) ~= nnz(safe_flat)
        error('yhat_safe_bm length (%d) != nnz(safe_flat) (%d).', numel(yhat_safe_bm), nnz(safe_flat));
    end

    yhat_full_bm = nan(nRows,1);
    yhat_full_bm(safe_flat) = yhat_safe_bm;

    status = zeros(nRows,1,'uint8');
    status(safe_flat) = 1;

    mat_path = fullfile(out_dir, [base_name '_fullpred_block_major.mat']);
    save(mat_path, 't_block','block_id','sim_id','y_true_bm','yhat_full_bm','status','safe_flat', ...
         'nBlocks','nsample','block_steps','sec_num','start_time','-v7.3');

    csv_path = fullfile(out_dir, [base_name '_fullpred_block_major.csv']);
    try
        if isempty(y_true_bm)
            T = table(t_block, block_id, sim_id, yhat_full_bm, status);
        else
            T = table(t_block, block_id, sim_id, y_true_bm, yhat_full_bm, status);
        end
        writetable(T, csv_path);
    catch
        csv_path = '';
    end

    paths.mat = mat_path;
    paths.csv = csv_path;
end
