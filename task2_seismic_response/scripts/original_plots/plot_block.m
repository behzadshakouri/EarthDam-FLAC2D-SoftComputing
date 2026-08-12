%% ------------------------------------------------------------
% Plot Option 3: Observed vs Predicted scatter
% Change: plot only every Nth point (to reduce density)
% Metrics are NOT affected (still computed on all SAFE rows).
% ------------------------------------------------------------
y_obs_plot = all_data(:,17);

safe_idx = row_valid;
fail_idx = ~row_valid;

y_obs_safe2  = y_obs_plot(safe_idx);
y_pred_safe2 = y_pred_full(safe_idx);

R2_safe = ErrorSafe.Corkare;

% ---- plot thinning knobs ----
plot_every_safe = 5;    % show every 5th SAFE point
plot_every_fail = 20;   % FAILED points are usually fewer; can thin more or set =plot_every_safe

% ---- thin SAFE points (deterministic) ----
nSafe = numel(y_obs_safe2);
keepSafe = false(nSafe,1);
keepSafe(1:plot_every_safe:end) = true;

% ---- thin FAIL points (deterministic) ----
y_obs_fail = y_obs_plot(fail_idx);
nFail = numel(y_obs_fail);
keepFail = false(nFail,1);
keepFail(1:plot_every_fail:end) = true;

% data to plot
y_obs_safe_plot  = y_obs_safe2(keepSafe);
y_pred_safe_plot = y_pred_safe2(keepSafe);

y_obs_fail_plot  = y_obs_fail(keepFail);
y_pred_fail_plot = zeros(sum(keepFail),1);

fig = figure('Visible','off');
hold on; grid on; box on;

% Slightly larger markers now that we plot fewer points
scatter(y_obs_safe_plot, y_pred_safe_plot, 10, [0 0 1], 'filled');
scatter(y_obs_fail_plot, y_pred_fail_plot, 18, [1 0 0], 'filled');

% Robust axis bounds (avoid 0-min squeeze)
valid = ~isnan(y_obs_plot);
if any(valid)
    xmin = prctile(y_obs_plot(valid), 0.5);
    xmax = prctile(y_obs_plot(valid), 99.5);
    if ~isfinite(xmin), xmin = min(y_obs_plot(valid)); end
    if ~isfinite(xmax), xmax = max(y_obs_plot(valid)); end
else
    xmin = 0; xmax = 1;
end

plot([xmin xmax], [xmin xmax], 'k--', 'LineWidth', 1.5);
xlim([xmin xmax]);
ylim([xmin xmax]);

xlabel('Observed');
ylabel('Predicted');
title(sprintf('%s%s Observed vs Predicted | SAFE R^2=%.4f', Point, Response, R2_safe));

legend({sprintf('SAFE (every %dth point)', plot_every_safe), ...
        sprintf('FAILED (every %dth point, shown at y=0)', plot_every_fail), ...
        '1:1'}, 'Location','best');

png_path = fullfile(Maku_PT2_Results, [base_name '_obs_vs_pred_scatter.png']);
saveas(fig, png_path);
close(fig);
disp(['Saved plot: ' png_path]);
