function files=generate_task3_nested_diagnostics()
%GENERATE_TASK3_NESTED_DIAGNOSTICS Plot saved primary-validation outputs.
% This function reads held-out predictions and permutation scores written by
% run_task3_fmrvr_experts_nested_validation; it does not refit any model.

analysisDir=fileparts(mfilename('fullpath'));
root=fileparts(analysisDir);
resultsDir=task3_analysis_results_root(root); figuresDir=fullfile(task3_output_root(root),'figures');
if ~isfolder(figuresDir),mkdir(figuresDir);end
predictions=readtable(fullfile(resultsDir,'fmrvr_experts_nested_predictions.csv'));
outputSummary=readtable(fullfile(resultsDir,'fmrvr_experts_nested_per_output_summary.csv'));
importance=readtable(fullfile(resultsDir,'fmrvr_experts_permutation_importance_summary.csv'));
files.all70=fullfile(figuresDir,'fmrvr_experts_all70_observed_predicted.png');
files.importance=fullfile(figuresDir,'fmrvr_experts_permutation_importance.png');
make_all70(predictions,outputSummary,figuresDir);
make_importance(importance,figuresDir);
make_output_map(outputSummary,figuresDir);
fprintf('Task 3 nested diagnostic figures generated from saved outer-test results.\n');
end

function make_all70(predictions,outputSummary,figuresDir)
responseLabels={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{pore}','\delta\gamma','\delta\nu_s'};
f=figure('Visible','off','Color','w','Renderer','opengl','Position',[20 20 4200 2900]);
for response=1:7
    for point=1:10
        ax=subplot(7,10,(response-1)*10+point); hold(ax,'on'); box(ax,'on');
        output=(point-1)*7+response;
        rows=predictions(predictions.output_column==output,:);
        summaryRow=outputSummary(outputSummary.output_column==output,:);
        if isempty(summaryRow) || summaryRow.valid_splits==0
            axis(ax,'off'); text(ax,.5,.5,'constant','Units','normalized', ...
                'HorizontalAlignment','center','FontSize',8,'Color',[.35 .35 .35]);
        else
            observed=rows.observed; predicted=rows.predicted;
            scatter(ax,observed,predicted,7,[.12 .42 .68],'filled', ...
                'MarkerFaceAlpha',.20,'MarkerEdgeAlpha',.20);
            lo=min([observed;predicted]); hi=max([observed;predicted]);
            if hi<=lo,hi=lo+1;end
            plot(ax,[lo hi],[lo hi],'k-','LineWidth',.75);
            plot(ax,[lo hi],[.5*lo .5*hi],':','Color',[.45 .45 .45],'LineWidth',.5);
            plot(ax,[lo hi],[2*lo 2*hi],':','Color',[.45 .45 .45],'LineWidth',.5);
            xlim(ax,[lo hi]); ylim(ax,[lo hi]); axis(ax,'square');
            text(ax,.04,.93,sprintf('R^2=%.2f',summaryRow.expert_mean_R2), ...
                'Units','normalized','FontSize',7,'VerticalAlignment','top');
            ax.FontSize=6; ax.TickDir='out'; ax.XTick=ax.XLim; ax.YTick=ax.YLim;
        end
        if response==1,title(ax,sprintf('P%d',point),'FontSize',10,'FontWeight','bold');end
        if point==1,ylabel(ax,responseLabels{response},'FontSize',9,'FontWeight','bold');end
        if point==10
            text(ax,1.08,.5,sprintf('R%d',response),'Units','normalized', ...
                'FontSize',9,'FontWeight','bold','Rotation',90, ...
                'HorizontalAlignment','center');
        end
    end
end

annotation(f,'textbox',[.38 .005 .24 .018],'String','Observed demand', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',12,'FontWeight','bold');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_experts_all70_observed_predicted.pdf'),'-dpdf','-opengl','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_experts_all70_observed_predicted.png'),'-dpng','-r300');
close(f);
end

function make_output_map(outputSummary,figuresDir)
r2=nan(7,10); delta=r2;
for i=1:height(outputSummary)
    r2(outputSummary.response(i),outputSummary.point(i))=outputSummary.expert_mean_R2(i);
    delta(outputSummary.response(i),outputSummary.point(i))=outputSummary.mean_delta_R2(i);
end
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{pore}','\delta\gamma','\delta\nu_s'};
f=figure('Visible','off','Color','w','Position',[100 100 1050 650]);
subplot(2,1,1);h=imagesc(r2);set(h,'AlphaData',~isnan(r2));
set(gca,'Color',[.86 .86 .86]);colorbar;caxis([0 1]);
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Monitoring point');ylabel('Response');title('Failure-aware FMRVR: mean held-out R^2');
subplot(2,1,2);h=imagesc(delta);set(h,'AlphaData',~isnan(delta));
set(gca,'Color',[.86 .86 .86]);colorbar;
lim=max(abs(delta(:)),[],'omitnan');if lim<=eps,lim=1;end;caxis([-lim lim]);
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Monitoring point');ylabel('Response');title('Mean R^2 gain over global multiscale FMRVR');
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_experts_output_map.pdf'),'-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_experts_output_map.png'),'-dpng','-r220');close(f);
end

function make_importance(summary,figuresDir)
plotRows=sortrows(summary,'mean_R2_decrease','ascend');
displayNames=feature_display_names(plotRows.feature);
f=figure('Visible','off','Color','w','Position',[100 100 920 580]);
barh(plotRows.mean_R2_decrease,'FaceColor',[.12 .42 .68]); hold on;
errorbar(plotRows.mean_R2_decrease,1:height(plotRows),plotRows.sd_R2_decrease, ...
    'horizontal','k.','LineWidth',1);
set(gca,'YTick',1:height(plotRows),'YTickLabel',displayNames, ...
    'TickLabelInterpreter','tex','FontSize',10,'TickDir','out');
xline(0,'k:'); grid on; xlabel('Decrease in held-out mean R^2 after permutation');
title('Outer-test permutation importance of ground-motion predictors');
for i=1:height(plotRows)
    labelX=plotRows.mean_R2_decrease(i)+plotRows.sd_R2_decrease(i)+.002;
    text(labelX,i,sprintf('%d/10',plotRows.positive_splits(i)), ...
        'VerticalAlignment','middle','FontSize',8);
end
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'fmrvr_experts_permutation_importance.pdf'), ...
    '-dpdf','-painters','-bestfit');
print(f,fullfile(figuresDir,'fmrvr_experts_permutation_importance.png'),'-dpng','-r300');
close(f);
end

function names=feature_display_names(raw)
names=cellstr(raw);
for i=1:numel(names)
    value=names{i};
    value=strrep(value,'PGA_g','PGA'); value=strrep(value,'PGV_m_s','PGV');
    value=strrep(value,'PGD_m','PGD'); value=strrep(value,'Arias_m_s','Arias intensity');
    value=strrep(value,'CAV_m_s','CAV'); value=strrep(value,'D5_95_s','D_{5-95}');
    value=strrep(value,'RMS_accel_g','RMS acceleration');
    value=strrep(value,'mean_frequency_Hz','Mean frequency');
    value=strrep(value,'predominant_period_s','Predominant period');
    value=strrep(value,'record_duration_s','Record duration');
    value=regexprep(value,'Sa_([0-9.]+)s_g','S_a($1 s)');
    names{i}=value;
end
end
