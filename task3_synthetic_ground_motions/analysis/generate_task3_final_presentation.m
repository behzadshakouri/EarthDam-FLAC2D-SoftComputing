function report=generate_task3_final_presentation()
%GENERATE_TASK3_FINAL_PRESENTATION Build paper-facing figures and tables.
% Reads the locked repeated-validation outputs; it does not fit a model.

analysisDir=fileparts(mfilename('fullpath'));

root=fileparts(analysisDir); addpath(root); setup_task3;
resultsDir=task3_analysis_results_root(root);
figuresDir=fullfile(task3_output_root(root),'figures');
tablesDir=fullfile(task3_output_root(root),'tables');
if ~isfolder(figuresDir),mkdir(figuresDir);end
if ~isfolder(tablesDir),mkdir(tablesDir);end

comparator=readtable(fullfile(resultsDir,'final_matched_comparator_metrics.csv'));
fmrvr=readtable(fullfile(resultsDir,'fmrvr_experts_nested_metrics.csv'));
fmrvrRows=table(fmrvr.repeat,repmat("Failure-aware FMRVR",height(fmrvr),1), ...
    fmrvr.expert_mean_R2,fmrvr.expert_median_R2,fmrvr.expert_mean_nRMSE, ...
    fmrvr.expert_mean_nMAE,fmrvr.expert_mean_a10, ...
    'VariableNames',comparator.Properties.VariableNames);
matched=[comparator;fmrvrRows];
make_comparator_dashboard(matched,figuresDir);

output=readtable(fullfile(resultsDir,'fmrvr_experts_nested_per_output_summary.csv'));
output=output(output.valid_splits>0 & isfinite(output.expert_mean_R2),:);
output=sortrows(output,'expert_mean_R2','ascend');
difficult=output(1:min(10,height(output)),:);
write_difficult_table(difficult,fullfile(tablesDir,'difficult_outputs.tex'));
writetable(difficult,fullfile(resultsDir,'fmrvr_experts_difficult_outputs.csv'));
make_severity_figure(resultsDir,figuresDir);
make_modal_figure(resultsDir,figuresDir);

report=struct('matched_metrics',matched,'difficult_outputs',difficult);
fprintf('Task 3 presentation artifacts generated: matched dashboard and difficult-output table.\n');
end

function make_comparator_dashboard(T,outDir)
methodValues=["Linear ridge (16 predictors)","Random forest","Failure-aware FMRVR"];
methodLabels={'Linear ridge','Random forest','Failure-aware FMRVR'};
colors=[.298 .471 .659;.961 .522 .094;.329 .635 .294];
vars={'mean_R2','mean_nRMSE','mean_nMAE','mean_a10'};
labels={'Mean R^2','Mean nRMSE','Mean nMAE','Mean a_{10}'};
f=figure('Visible','off','Color','w','Renderer','painters','Position',[60 60 1600 900]);
letters='abcd';
for metric=1:4
    ax=subplot(2,2,metric); hold(ax,'on');
    values=nan(10,3);
    for method=1:3
        rows=T(string(T.method)==methodValues(method),:);
        rows=sortrows(rows,'repeat'); values(:,method)=rows.(vars{metric});
    end
    for repeat=1:10
        plot(ax,1:3,values(repeat,:),'-','Color',[.82 .82 .82],'LineWidth',.7);
    end
    for method=1:3
        scatter(ax,method*ones(10,1),values(:,method),46,colors(method,:), ...
            'filled','MarkerEdgeColor',[.25 .25 .25],'LineWidth',.35);
        plot(ax,[method-.22 method+.22],repmat(mean(values(:,method)),1,2), ...
            'Color',colors(method,:),'LineWidth',3);
    end
    ax.XTick=1:3; ax.XTickLabel=methodLabels; ax.FontName='Arial';
    ax.FontSize=11; ax.TickDir='out'; ax.Box='on'; grid(ax,'on'); ax.GridAlpha=.16;
    ylabel(ax,labels{metric},'Interpreter','tex');
    text(ax,.02,.96,sprintf('(%c)',letters(metric)),'Units','normalized', ...
        'VerticalAlignment','top','FontWeight','bold','FontSize',13);
end
annotation(f,'textbox',[.30 .955 .40 .03], ...
    'String','Matched outer-split performance of the final models', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',14,'FontWeight','bold');
set(f,'PaperPositionMode','auto');
print(f,fullfile(outDir,'final_matched_comparator_dashboard.pdf'), ...
    '-dpdf','-painters','-bestfit');
print(f,fullfile(outDir,'final_matched_comparator_dashboard.png'),'-dpng','-r300');
close(f);
end

function write_difficult_table(T,path)
family={'Horizontal displacement ($\Delta_x$)', ...
    'Vertical displacement ($\Delta_y$)', ...
    'Horizontal normal stress ($\sigma_{xx}$)', ...
    'Vertical normal stress ($\sigma_{yy}$)', ...
    'Pore-water pressure ($P_{\mathrm{pore}}$)', ...
    'Incremental shear strain ($\delta\gamma$)', ...
    'Incremental volumetric strain ($\delta\nu_s$)'};
fid=fopen(path,'w'); assert(fid>=0,'Could not write %s.',path);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'\\begin{table}[H]\n\\centering\n');
fprintf(fid,['\\caption{Ten most difficult nonconstant response--location outputs for the failure-aware FMRVR. ' ...
    'Values summarize the same ten held-out outer splits used for the primary assessment.}\n']);
fprintf(fid,'\\label{tab:difficult-outputs}\n\\small\n');
fprintf(fid,'\\begin{adjustbox}{max width=\\textwidth}\n');
fprintf(fid,'\\begin{tabular}{llrrrr}\n\\toprule\n');
fprintf(fid,'Output & Response family & Mean $R^2$ & SD $R^2$ & $\\Delta R^2$ & Mean nRMSE \\\\\n');
fprintf(fid,'\\midrule\n');
for i=1:height(T)
    fprintf(fid,'%s & %s & %.3f & %.3f & %+.3f & %.3f \\\\\n', ...
        char(T.label(i)),family{T.response(i)},T.expert_mean_R2(i), ...
        T.expert_sd_R2(i),T.mean_delta_R2(i),T.expert_mean_nRMSE(i));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n');
fprintf(fid,['\\begin{flushleft}\n\\footnotesize $\\Delta R^2$ is the mean change relative to the ' ...
    'global multiscale FMRVR on matched outer partitions.\n\\end{flushleft}\n']);
fprintf(fid,'\\end{table}\n');
end

function make_severity_figure(resultsDir,figuresDir)
outer=readtable(fullfile(resultsDir,'fmrvr_severity_family_nested_metrics.csv'));
family=readtable(fullfile(resultsDir,'fmrvr_severity_family_nested_family_summary.csv'));
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{pore}','\delta\gamma','\delta\nu_s'};
f=figure('Visible','off','Color','w','Position',[100 100 1100 430]);
subplot(1,2,1);plot(outer.repeat,outer.baseline_mean_R2,'-o');hold on;
plot(outer.repeat,outer.structured_mean_R2,'-s');grid on;
xlabel('Outer split');ylabel('Mean held-out R^2');
legend('Binary-gated experts','Severity/family FMRVR','Location','best');
title('Matched nested validation');
subplot(1,2,2);bar(family.mean_delta_R2);grid on;
set(gca,'XTick',1:7,'XTickLabel',symbols,'TickLabelInterpreter','tex');
ylabel('Mean \DeltaR^2','Interpreter','tex');title('Gain by response family');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_severity_family_nested_validation.pdf'), ...
    '-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_severity_family_nested_validation.png'),'-dpng','-r220');close(f);
end

function make_modal_figure(resultsDir,figuresDir)
curves=readtable(fullfile(resultsDir,'modal_transfer_curves.csv'));
modal=readtable(fullfile(resultsDir,'modal_periods_development_only.csv'));
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{pore}','\delta\gamma','\delta\nu_s'};
f=figure('Visible','off','Color','w','Position',[100 100 980 650]);
subplot(2,1,1);hold on;
for r=1:7
    plot(curves.period_s,curves.(sprintf('family_%d_median',r)), ...
        'LineWidth',1.2,'DisplayName',symbols{r});
end
set(gca,'XScale','log','XDir','normal');grid on;xlabel('Period (s)');
ylabel('Detrended log transfer');title('Sentinel-free development simulations');
legend('Location','eastoutside','Interpreter','tex');
subplot(2,1,2);plot(curves.period_s,curves.consensus_score,'k','LineWidth',1.8);hold on;
peakScore=interp1(curves.period_s,curves.consensus_score,modal.period_s,'linear');
scatter(modal.period_s,peakScore,65,'filled');
for k=1:height(modal)
    text(modal.period_s(k),peakScore(k),sprintf('  T%d=%.3f s',k,modal.period_s(k)));
end
set(gca,'XScale','log','XDir','normal');grid on;xlabel('Period (s)');
ylabel('Consensus peak score');title('Modal-period candidates');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'modal_period_transfer_analysis.pdf'), ...
    '-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'modal_period_transfer_analysis.png'),'-dpng','-r220');close(f);
end
