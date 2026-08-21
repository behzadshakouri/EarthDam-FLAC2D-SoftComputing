%% IAA_heatmap_full_NO_spectra.m
% Reads an IAA record (time in seconds, acceleration in g) and exports:
%  IAA: IAA acceleration + PGA envelopes (running max, linearized, stepped)
%  a_PSA_heatmap: PSA heatmap (Period × Time) with contour lines
%  b_PSV_heatmap: PSV heatmap (Period × Time) with contour lines
%
% Outputs (PNG):
%   IAA.png
%   a_PSA_heatmap.png
%   b_PSV_heatmap.png
%
% Notes (units + calculations):
% - Heatmaps are computed from cumulative windows [0, t] (IAA intensification interpretation).
% - Linear SDOF response computed with Newmark-beta (average acceleration).
% - Input acceleration is in g and converted to m/s^2 internally for dynamics.
% - PSA = (wn^2 * umax) / g0  => reported in g
% - PSV = (wn * umax)         => reported in m/s
%
% Important:
% - This computes pseudo-spectra (PSA/PSV) from max relative displacement (umax).
% - If you need true SA = max|u'' + ag|, we can add it as a separate heatmap.

clear; clc;

%% ---------------- USER SETTINGS ----------------
Address = 'E:\University\My Thesis\Flac model\New\';
cd(Address);
inFile = 'IAA_record.csv';     % CSV: [time(s), accel(g)] OR [accel(g)]
hasTimeColumn = true;          % true if 2 columns [t, a_g], false if only a_g
dt_if_no_time = 0.01;          % used only if hasTimeColumn=false

zeta = 0.05;                   % damping ratio (5%)
Tmin = 0.05;                   % minimum period (s)
Tmax = 2.0;                    % maximum period (s)
nT   = 120;                    % number of periods for heatmap
nSteps = 10;                   % stepped envelope levels in IAA panel

% Heatmap contour levels
nContourLevels = 10;

% Output PNG names
outIAA = 'IAA.png';
outPSA = 'a_PSA_heatmap.png';
outPSV = 'b_PSV_heatmap.png';

dpi = 300;

% Font sizes
fsAxes   = 18;
fsLabel  = 20;
fsTitle  = 20;
fsLegend = 16;
fsCbar   = 18;
% -----------------------------------------------

%% ---------------- READ IAA RECORD ----------------
M = readmatrix(inFile);

if hasTimeColumn
    t  = M(:,1);
    ag = M(:,2);               % acceleration in g
    dt = median(diff(t));
else
    ag = M(:,1);
    dt = dt_if_no_time;
    t  = (0:numel(ag)-1)' * dt;
end

% Cleanup
mask = isfinite(t) & isfinite(ag);
t = t(mask); ag = ag(mask);
t = t(:); ag = ag(:);

% Ensure monotonically increasing time
[t, ord] = sort(t);
ag = ag(ord);

T_total = t(end); %#ok<NASGU>

% Units
g0 = 9.80665;
ag_ms2 = ag * g0;

%% ---------------- IAA: ACCELERATION + ENVELOPES ----------------
absA = abs(ag);

% Running max envelope (cumulative)
env_run = cummax(absA);

% Linearized envelope (least squares fit to env_run)
p = polyfit(t, env_run, 1);
env_lin = polyval(p, t);
env_lin(env_lin < 0) = 0;

% Stepped envelope (nSteps)
edges = linspace(t(1), t(end), nSteps+1);
env_step = zeros(size(t));
for k = 1:nSteps
    idx = (t >= edges(k)) & (t < edges(k+1));
    if any(idx)
        env_step(idx) = max(env_run(idx));
    end
end

% include last point robustly
if numel(t) > 1
    env_step(end) = env_step(end-1);
else
    env_step(end) = env_run(end);
end

figIAA = figure('Color','w','Position',[100 100 1200 450]);

plot(t, ag, 'k', 'LineWidth', 1.3); hold on;
plot(t,  env_run, 'r--', 'LineWidth', 1.5);
plot(t, -env_run, 'r--', 'LineWidth', 1.5);
plot(t,  env_lin, 'b:',  'LineWidth', 2.0);
plot(t, -env_lin, 'b:',  'LineWidth', 2.0);
plot(t,  env_step, 'm-.', 'LineWidth', 1.7);
plot(t, -env_step, 'm-.', 'LineWidth', 1.7);

grid on;
xlabel('Time (s)', 'FontSize', fsLabel);
ylabel('Acceleration (g)', 'FontSize', fsLabel);
set(gca, 'FontSize', fsAxes);

% title('IAA Acceleration Function with Increasing PGA Envelopes', 'FontSize', fsTitle);

% Compact legend (avoid duplicates from symmetric curves)
lgd = legend({'IAA acceleration', ...
              'PGA envelope (running max |a|)', ...
              'PGA envelope (linearized)', ...
              sprintf('PGA envelope (stepped, %d levels)', nSteps)}, ...
              'Location','northwest');
lgd.Box = 'off';
lgd.FontSize = fsLegend;

exportgraphics(figIAA, outIAA, 'Resolution', dpi);

%% ---------------- RESPONSE HEATMAPS (PSA, PSV) ----------------
% Period vector and natural circular frequency
Tvec = linspace(Tmin, Tmax, nT);
w = 2*pi./Tvec;

PSA = nan(nT, numel(t));   % PSA (g)  => size: [period, time]
PSV = nan(nT, numel(t));   % PSV (m/s)

% Newmark-beta (average acceleration) constants
beta  = 1/4;
gamma = 1/2;

dtloc = dt;

a0 = 1/(beta*dtloc^2);
a1 = gamma/(beta*dtloc);
a2 = 1/(beta*dtloc);
a3 = 1/(2*beta) - 1;
a4 = gamma/beta - 1;
a5 = dtloc*(gamma/(2*beta) - 1);

% ---- Calculation check notes ----
% We solve for relative displacement u(t) of SDOF with m=1:
%   u'' + c u' + k u = -ag(t)
% where:
%   k = wn^2, c = 2*zeta*wn
% PSA = wn^2 * umax / g0
% PSV = wn * umax
% This matches standard pseudo-spectrum definitions and keeps units correct.

% Compute cumulative-window pseudo-spectra for each time index it
for it = 2:numel(t)
    ag_t = ag_ms2(1:it);

    for k = 1:nT
        wn  = w(k);
        ks  = wn^2;          % m=1
        cs  = 2*zeta*wn;     % m=1

        % Effective stiffness
        keff = ks + a0 + a1*cs;

        % State (relative)
        u = 0; v = 0; acc_rel = 0;
        umax = 0;

        for n = 1:numel(ag_t)
            % Base excitation as effective force p = -ag (m=1)
            pext = -ag_t(n);

            % Effective load (standard Newmark form)
            peff = pext + (a0*u + a2*v + a3*acc_rel) + cs*(a1*u + a4*v + a5*acc_rel);

            % Solve for displacement
            u_new = peff / keff;

            % Update acceleration and velocity
            acc_new = a0*(u_new - u) - a2*v - a3*acc_rel;
            v_new   = v + dtloc*((1-gamma)*acc_rel + gamma*acc_new);

            u = u_new; v = v_new; acc_rel = acc_new;

            umax = max(umax, abs(u));
        end

        % Pseudo measures (units checked)
        PSA(k,it) = (wn^2 * umax) / g0; % (m/s^2)/g0 => g
        PSV(k,it) = wn * umax;          % (rad/s)*m => m/s
    end
end

%% -------- a_PSA_heatmap --------
figPSA = figure('Color','w','Position',[100 100 900 520]);

imagesc(t, Tvec, PSA);
set(gca, 'YDir', 'reverse', 'FontSize', fsAxes);
cb = colorbar;
cb.Label.String = 'PSA (g)';
cb.Label.FontSize = fsCbar;
xlabel('Time (s)', 'FontSize', fsLabel);
ylabel('Period (s)', 'FontSize', fsLabel);
% title('Pseudo-Acceleration Heatmap (5% damping)', 'FontSize', fsTitle);
hold on;

levels = linspace(min(PSA(isfinite(PSA))), max(PSA(isfinite(PSA))), nContourLevels);
contour(t, Tvec, PSA, levels, 'k', 'LineWidth', 0.8);

exportgraphics(figPSA, outPSA, 'Resolution', dpi);

%% -------- b_PSV_heatmap --------
figPSV = figure('Color','w','Position',[100 100 900 520]);

imagesc(t, Tvec, PSV);
set(gca, 'YDir', 'reverse', 'FontSize', fsAxes);
cb = colorbar;
cb.Label.String = 'PSV (m/s)';
cb.Label.FontSize = fsCbar;
xlabel('Time (s)', 'FontSize', fsLabel);
ylabel('Period (s)', 'FontSize', fsLabel);
% title('Pseudo-Velocity Heatmap (5% damping)', 'FontSize', fsTitle);
hold on;

levels = linspace(min(PSV(isfinite(PSV))), max(PSV(isfinite(PSV))), nContourLevels);
contour(t, Tvec, PSV, levels, 'k', 'LineWidth', 0.8);

exportgraphics(figPSV, outPSV, 'Resolution', dpi);

disp('Done. Exported:');
disp(outIAA);
disp(outPSA);
disp(outPSV);