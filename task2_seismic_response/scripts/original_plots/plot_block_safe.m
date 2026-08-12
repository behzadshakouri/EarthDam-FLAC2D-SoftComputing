%% ============================================================
% Plot: Observed vs Predicted scatter (SAFE ONLY)
% - skips FAILED points entirely
% - axis bounds from SAFE ONLY
% - thinning for speed/clarity
% ============================================================
y_obs_plot = all_data(:,17);

safe_idx = row_valid;

y_obs_safe2  = y_obs_plot(safe_idx);
y_pred_safe2 = y_pred_full(safe_idx);

R2_safe = ErrorSafe.Corkare;

% ---- plot thinning knobs ----
plot_every_safe = 5;    % show every 5th SAFE point

% ---- thin SAFE points (deterministic) ----
nSafe = numel(y_obs_safe2);
keepSafe = false(nSafe,1);
keepSafe(1:plot_every_safe:end) = true;

y_obs_safe_plot  = y_obs_safe2(keepSafe);
y_pred_safe_plot = y_pred_safe2(keepSafe);

% -------------------------------
% Axis bounds from SAFE ONLY
% -------------------------------
validSafe = isfinite(y_obs_safe2) & isfinite(y_pred_safe2) & ...
            ~isnan(y_obs_safe2) & ~isnan(y_pred_safe2);

if any(validSafe)
    xmin = prctile(y_obs_safe2(validSafe), 0.5);
    xmax = prctile(y_obs_safe2(validSafe), 99.5);

    ymin = prctile(y_pred_safe2(validSafe), 0.5);
    ymax = prctile(y_pred_safe2(validSafe), 99.5);

    lo = min(xmin, ymin);
    hi = max(xmax, ymax);

    if ~isfinite(lo), lo = min([y_obs_safe2(validSafe); y_pred_safe2(validSafe)]); end
    if ~isfinite(hi), hi = max([y_obs_safe2(validSafe); y_pred_safe2(validSafe)]); end
else
    lo = 0; hi = 1;
end

pad = 0.02 * (hi - lo + eps);
lo = lo - pad;
hi = hi + pad;

fig = figure('Visible','off');
hold on; grid on; box on;

% SAFE ONLY
scatter(y_obs_safe_plot, y_pred_safe_plot, 10, [0 0 1], 'filled');

plot([lo hi], [lo hi], 'k--', 'LineWidth', 1.5);
xlim([lo hi]);
ylim([lo hi]);

xlabel('Observed');
ylabel('Predicted');
title(sprintf('%s%s Obs vs Pred | SAFE R^2=%.4f | fail=%s | asinh=%d', ...
    Point, Response, R2_safe, string(failure_mode), use_asinh_target));

legend({sprintf('SAFE (every %dth)', plot_every_safe), '1:1'}, 'Location','best');

png_path = fullfile(caseDir, [base_name '_obs_vs_pred_scatter.png']);
saveas(fig, png_path);
close(fig);
disp(['Saved plot: ' png_path]);
