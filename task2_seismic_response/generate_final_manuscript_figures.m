function outDir = generate_final_manuscript_figures(handoffFile, outDir)
%GENERATE_FINAL_MANUSCRIPT_FIGURES Final aggregate figures for the ASOC paper.
% Reads the saved final handoff workbook only; no model is retrained.
% Compatible with MATLAB R2020a.

root = setup_task2;
if nargin < 1 || isempty(handoffFile)
    candidates = dir(fullfile(root,'results','**','task2_final_manuscript_handoff_*.xlsx'));
    if isempty(candidates)
        error('Task2:MissingHandoff', ...
            'Pass the final task2_final_manuscript_handoff_*.xlsx file.');
    end
    [~,k] = max([candidates.datenum]);
    handoffFile = fullfile(candidates(k).folder,candidates(k).name);
end
if nargin < 2 || isempty(outDir)
    outDir = fullfile(root,'results','final_manuscript_figures');
end
if ~isfolder(outDir), mkdir(outDir); end

caseMetrics = readtable(handoffFile,'Sheet','selected_case_metrics');
modelSummary = readtable(handoffFile,'Sheet','model_summary');
byResponse = readtable(handoffFile,'Sheet','by_response');
neuronSweep = readtable(handoffFile,'Sheet','neuron_sweep');

caseMetrics = caseMetrics(caseMetrics.constant_reference==0,:);
models = {'ELM','ELMABC','ELMACOR','ELMIGWO'};
displayNames = {'ELM','ELM-ABC','ELM-ACOR','ELM-IGWO'};
colors = [0.298 0.471 0.659; 0.961 0.522 0.094; ...
          0.612 0.459 0.373; 0.329 0.635 0.294];
metricVars = {'R2','nRMSE','nMAE','a10'};
metricLabels = {'R^2','nRMSE','nMAE','a_{10}'};
higherIsBetter = [true false false true];

make_distribution_dashboard(caseMetrics,models,displayNames,colors, ...
    metricVars,metricLabels,outDir);
make_wins_figure(caseMetrics,models,displayNames,metricVars, ...
    metricLabels,higherIsBetter,outDir);
make_model_summary(modelSummary,models,displayNames,colors,outDir);
make_response_summary(byResponse,outDir);
make_neuron_sweep(neuronSweep,models,displayNames,colors,outDir);

fprintf('Final manuscript figures written to:\n%s\n',outDir);
end

function make_distribution_dashboard(T,models,names,colors,vars,labels,outDir)
f=new_figure(); tl=tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');
rng(1,'twister');
responseLabels=final_response_labels();
responseColors=lines(7);
responseMarkers={'o','s','^','d','v','>','p'};
for j=1:4
    ax=nexttile(tl); values=[]; groups=[];
    for i=1:4
        q=strcmpi(string(T.model),models{i}); v=T.(vars{j})(q); v=v(isfinite(v));
        values=[values;v]; groups=[groups;i*ones(numel(v),1)]; %#ok<AGROW>
    end
    boxplot(ax,values,groups,'Labels',names,'Symbol','','Widths',0.58, ...
        'Colors',[0.58 0.58 0.95]);
    hold(ax,'on'); legendHandles=gobjects(7,1);
    for g=1:7
        for i=1:4
            q=strcmpi(string(T.model),models{i}) & T.response==g;
            y=T.(vars{j})(q); y=y(isfinite(y));
            if isempty(y),continue;end
            x=i+(rand(size(y))-0.5)*0.34;
            h=scatter(ax,x,y,22,responseColors(g,:),responseMarkers{g}, ...
                'filled','MarkerEdgeColor',[0.25 0.25 0.25], ...
                'LineWidth',0.35);
            if ~isgraphics(legendHandles(g)),legendHandles(g)=h;end
        end
    end
    ylabel(ax,labels{j},'Interpreter','tex');
    style_axis(ax); panel_label(ax,j);
    if j==1
        valid=isgraphics(legendHandles);
        lg=legend(ax,legendHandles(valid),responseLabels(valid), ...
            'Location','eastoutside','Interpreter','tex','Box','on');
        lg.FontName='Arial'; lg.FontSize=9; lg.Color='w';
        title(lg,'Response','FontWeight','bold');
    end
end
save_figure(f,fullfile(outDir,'COMPARE_dashboard.png')); close(f);
end

function make_wins_figure(T,models,names,vars,labels,higher,outDir)
wins=zeros(4,4); top2=zeros(4,4);
for j=1:4
    for p=1:10
        for r=1:7
            vals=nan(4,1);
            for i=1:4
                q=strcmpi(string(T.model),models{i}) & T.point==p & T.response==r;
                if nnz(q)==1, vals(i)=T.(vars{j})(q); end
            end
            if any(~isfinite(vals)), continue; end
            if higher(j), [~,ord]=sort(vals,'descend'); else, [~,ord]=sort(vals,'ascend'); end
            wins(j,ord(1))=wins(j,ord(1))+1;
            top2(j,ord(1:2))=top2(j,ord(1:2))+1;
        end
    end
end
f=new_figure(); tl=tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');
for j=1:4
    ax=nexttile(tl); b=bar(ax,[wins(j,:)' (top2(j,:)'-wins(j,:)')], ...
        0.76,'stacked');
    b(1).FaceColor=[0.298 0.471 0.659]; b(2).FaceColor=[0.949 0.647 0.255];
    ax.XTick=1:4; ax.XTickLabel=names; ylim(ax,[0 67]);
    ylabel(ax,'Count (out of 67)'); style_axis(ax); panel_label(ax,j);
    if j==1
        lg=legend(ax,{'Winner','Additional top-two'}, ...
            'Location','northoutside','Orientation','horizontal','Box','on');
        lg.FontName='Arial'; lg.FontSize=9; lg.Color='w';
    end
end
save_figure(f,fullfile(outDir,'COMPARE_wins_top2.png')); close(f);
writetable(wins_table(wins,top2,names,vars), ...
    fullfile(outDir,'COMPARE_wins_top2.csv'));
end

function make_model_summary(T,models,names,colors,outDir)
vars={'mean_R2','mean_nRMSE','mean_nMAE','mean_a10'};
labels={'Mean R^2','Mean nRMSE','Mean nMAE','Mean a_{10}'};
f=new_figure(); tl=tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');
for j=1:4
    ax=nexttile(tl); vals=nan(4,1);
    for i=1:4, vals(i)=T.(vars{j})(strcmpi(string(T.model),models{i})); end
    b=bar(ax,vals,'FaceColor','flat'); b.CData=colors;
    ax.XTick=1:4; ax.XTickLabel=names; ylabel(ax,labels{j},'Interpreter','tex');
    style_axis(ax); panel_label(ax,j); annotate_bars(ax,b,vals);
end
save_figure(f,fullfile(outDir,'MODEL_summary_final.png')); close(f);
end

function make_response_summary(T,outDir)
q=strcmpi(string(T.model),'ELMIGWO'); T=sortrows(T(q,:),'response');
vars={'mean_R2','mean_nRMSE','mean_nMAE','mean_a10'};
labels={'Mean R^2','Mean nRMSE','Mean nMAE','Mean a_{10}'};
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{\rm pore}','\delta\gamma','\delta\nu_s'};
f=new_figure(); tl=tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');
for j=1:4
    ax=nexttile(tl); vals=T.(vars{j}); b=bar(ax,vals,'FaceColor',[0.329 0.635 0.294]);
    ax.XTick=1:7; ax.XTickLabel=symbols; ax.TickLabelInterpreter='tex';
    ylabel(ax,labels{j},'Interpreter','tex');
    style_axis(ax); panel_label(ax,j); annotate_bars(ax,b,vals);
end
save_figure(f,fullfile(outDir,'ELMIGWO_by_response_final.png')); close(f);
end

function make_neuron_sweep(T,models,names,colors,outDir)
vars={'mean_R2','mean_nRMSE','mean_nMAE','mean_a10'};
labels={'Mean R^2','Mean nRMSE','Mean nMAE','Mean a_{10}'};
f=new_figure(); tl=tiledlayout(f,2,2,'Padding','compact','TileSpacing','compact');
for j=1:4
    ax=nexttile(tl); hold(ax,'on');
    for i=1:4
        q=strcmpi(string(T.method),models{i}); D=sortrows(T(q,:),'hidden_neurons');
        plot(ax,D.hidden_neurons,D.(vars{j}),'-o','LineWidth',1.7, ...
            'MarkerSize',6,'Color',colors(i,:),'DisplayName',names{i});
    end
    xlabel(ax,'Hidden neurons'); ylabel(ax,labels{j},'Interpreter','tex');
    style_axis(ax); panel_label(ax,j);
    ax.XTick=unique(T.hidden_neurons)';
    if j==1
        lg=legend(ax,'Location','best','Box','on');
        lg.FontName='Arial'; lg.FontSize=9; lg.Color='w';
    end
end
save_figure(f,fullfile(outDir,'NEURON_sweep_final.png')); close(f);
end

function f=new_figure()
f=figure('Visible','off','Color','w','Renderer','painters', ...
    'Position',[60 60 1600 830]);
end

function style_axis(ax)
grid(ax,'on'); ax.GridAlpha=0.16; ax.Box='on'; ax.LineWidth=0.8;
ax.FontName='Arial'; ax.FontSize=12; ax.TickDir='out';
end

function panel_label(ax,index)
letters='abcd';
text(ax,0.015,0.975,sprintf('(%c)',letters(index)), ...
    'Units','normalized','HorizontalAlignment','left', ...
    'VerticalAlignment','top','FontName','Arial','FontSize',13, ...
    'FontWeight','bold','Color','k');
end

function annotate_bars(ax,b,vals)
pad=max(abs(vals))*0.025; if pad==0, pad=0.01; end
for i=1:numel(vals)
    text(ax,b.XData(i),vals(i)+pad,sprintf('%.3f',vals(i)), ...
        'HorizontalAlignment','center','FontSize',9);
end
end

function save_figure(f,path)
exportgraphics(f,path,'Resolution',300);
end

function T=wins_table(wins,top2,names,vars)
metric=strings(16,1); model=strings(16,1); win=zeros(16,1); top=zeros(16,1); k=0;
for j=1:4
    for i=1:4
        k=k+1; metric(k)=vars{j}; model(k)=names{i};
        win(k)=wins(j,i); top(k)=top2(j,i);
    end
end
T=table(metric,model,win,top,'VariableNames',{'metric','model','wins','top_two'});
end
