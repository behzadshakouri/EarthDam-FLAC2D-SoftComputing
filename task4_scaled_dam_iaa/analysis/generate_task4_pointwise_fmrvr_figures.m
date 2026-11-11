function generate_task4_pointwise_fmrvr_figures(outputDir)
%GENERATE_TASK4_POINTWISE_FMRVR_FIGURES Paper figures from final results.
analysisDir = fileparts(mfilename('fullpath'));
root = fileparts(analysisDir);
cfg = task4_config(root);
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(cfg.output_root, 'pointwise_fmrvr');
end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

resultsDir = fullfile(cfg.results_dir, 'scale_aware', 'production');
outer = readtable(fullfile(resultsDir, 'pointwise_fmrvr_outer_metrics.csv'));
perOutput = readtable(fullfile(resultsDir, 'pointwise_fmrvr_per_output.csv'));
byPoint = readtable(fullfile(resultsDir, 'pointwise_fmrvr_point_summary.csv'));
byResponse = readtable(fullfile(resultsDir, 'pointwise_fmrvr_response_summary.csv'));
byScale = readtable(fullfile(resultsDir, 'pointwise_fmrvr_scale_summary.csv'));
saved = load(fullfile(resultsDir, 'pointwise_fmrvr_split1.mat'), 'splitOne');
s = saved.splitOne;

symbols = {'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}', ...
    'P_{\rm pore}','\delta\gamma','\delta\nu_s'};
blue = [0 .447 .741]; orange = [.85 .325 .098]; green = [.18 .58 .32];

% Quantify the variability across complete-realization outer tests for the
% same grouped summaries shown in the paper.
repeats = unique(perOutput.repeat);
pointStd = nan(height(byPoint),1);
for i = 1:height(byPoint)
    splitMean = nan(numel(repeats),1);
    for k = 1:numel(repeats)
        rows = perOutput.repeat == repeats(k) & ...
            perOutput.point == byPoint.point(i) & ~perOutput.constant;
        splitMean(k) = mean(perOutput.R2(rows),'omitnan');
    end
    pointStd(i) = std(splitMean,'omitnan');
end
responseStd = nan(height(byResponse),1);
for i = 1:height(byResponse)
    splitMean = nan(numel(repeats),1);
    for k = 1:numel(repeats)
        rows = perOutput.repeat == repeats(k) & ...
            perOutput.response == byResponse.response(i) & ~perOutput.constant;
        splitMean(k) = mean(perOutput.R2(rows),'omitnan');
    end
    responseStd(i) = std(splitMean,'omitnan');
end

f = figure('Visible','off','Color','w','Position',[100 100 900 480]);
plot(outer.repeat,outer.mean_R2,'-o','Color',blue,'LineWidth',1.8, ...
    'MarkerSize',6,'MarkerFaceColor','w','DisplayName','Mean over outputs'); hold on;
plot(outer.repeat,outer.median_R2,'-s','Color',orange,'LineWidth',1.8, ...
    'MarkerSize',6,'MarkerFaceColor','w','DisplayName','Median over outputs');
yline(.9,':','R^2=0.90','LabelHorizontalAlignment','left','LineWidth',1.0, ...
    'HandleVisibility','off'); grid on; xlim([1 10]); ylim([.87 .91]);xticks(1:10);
xlabel('Outer split'); ylabel('Held-out R^2');
legend('Location','southoutside','Orientation','horizontal','Box','off');
set(gca,'FontName','Arial','FontSize',10.5,'TickDir','out','LineWidth',.8, ...
    'GridAlpha',.16,'MinorGridAlpha',.10);
export_pair(f,outputDir,'task4_repeated_validation'); close(f);

f = figure('Visible','off','Color','w','Position',[100 100 1080 470]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
nexttile; bar(byPoint.point,byPoint.mean_R2,'FaceColor',blue); hold on;
errorbar(byPoint.point,byPoint.mean_R2,pointStd,'k.','LineWidth',1.0,'CapSize',5);
yline(.8,':'); grid on;
ylim([.74 1]); xlabel('Response-extraction point'); ylabel('Mean held-out R^2'); title('Performance by response-extraction point');
nexttile; bar(byResponse.response,byResponse.mean_R2,'FaceColor',orange); hold on;
errorbar(byResponse.response,byResponse.mean_R2,responseStd,'k.','LineWidth',1.0,'CapSize',5);
yline(.8,':'); grid on;
ylim([.78 1]); set(gca,'XTick',1:7,'XTickLabel',symbols,'TickLabelInterpreter','tex');
ylabel('Mean held-out R^2'); title('Performance by response family');
export_pair(f,outputDir,'task4_point_response_performance'); close(f);

map = nan(7,10);
for output = 1:70
    rows = perOutput.output_column == output & ~perOutput.constant;
    if any(rows)
        point = ceil(output/7); response = output - (point-1)*7;
        map(response,point) = mean(perOutput.R2(rows));
    end
end
f = figure('Visible','off','Color','w','Position',[100 100 1050 450]);
h = imagesc(map); set(h,'AlphaData',~isnan(map)); set(gca,'Color',[.88 .88 .88]);
finiteMap = map(isfinite(map));
caxis([floor(20*min(finiteMap))/20 ceil(20*max(finiteMap))/20]); colorbar;
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Response-extraction point'); ylabel('Response'); title('Mean held-out R^2 over ten scale-stratified splits');
for r=1:7
    for p=1:10
        if isfinite(map(r,p))
            col='k'; if map(r,p)<.72, col='w'; end
            text(p,r,sprintf('%.2f',map(r,p)), ...
                'HorizontalAlignment','center','FontSize',8,'Color',col);
        end
    end
end
export_pair(f,outputDir,'task4_output_map'); close(f);

f = figure('Visible','off','Color','w','Position',[100 100 1100 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
labels=categorical(compose('%.2f',byScale.scale_factor));
labels=reordercats(labels,compose('%.2f',byScale.scale_factor));
nexttile;
b=bar(labels,[byScale.median_R2 byScale.fraction_R2_ge_08],.78,'grouped');
b(1).FaceColor=blue;b(2).FaceColor=green;grid on;ylim([.40 .90]);
ylabel('Performance');xlabel('Geometric scale factor, \lambda');
legend('Median R^2','Fraction R^2 \geq 0.8','Location','southoutside', ...
    'Orientation','horizontal','Box','off');
title('Accuracy by modeled scale');
nexttile;
bar(labels,byScale.mean_nRMSE,.62,'FaceColor',orange);grid on;ylim([0 .24]);
ylabel('Mean nRMSE');xlabel('Geometric scale factor, \lambda');
title('Normalized error by modeled scale');
set(findall(f,'Type','axes'),'FontName','Arial','FontSize',10.5,'TickDir','out', ...
    'LineWidth',.8,'GridAlpha',.16,'MinorGridAlpha',.10);
export_pair(f,outputDir,'task4_scale_performance'); close(f);

% Task 2-style all-70 observed-versus-predicted grid with manual axes so
% the 70 panels remain large and nearly square in the manuscript.
plot_all70_task2_style(s,perOutput,symbols,[.55 .28 .68],blue,green,outputDir);
end

function export_pair(f,folder,name)
% Export to the content bounds so manuscript inclusion does not inherit a
% letter-size PDF canvas around a landscape plot.
exportgraphics(f,fullfile(folder,[name '.pdf']),'ContentType','vector');
exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300);
end

function plot_all70_task2_style(s,perOutput,symbols,pointColor,blue,green,outputDir)
rng(4);
f=figure('Visible','off','Color','w','Renderer','opengl','Position',[20 20 1200 1750]);
left=.095;right=.018;bottom=.055;top=.070;hgap=.012;vgap=.012;
tileW=(1-left-right-6*hgap)/7;tileH=(1-bottom-top-9*vgap)/10;
units={'[m]','[m]','[Pa]','[Pa]','[Pa]','[-]','[-]'};
for response=1:7
    for point=1:10
        output=(point-1)*7+response;
        pos=[left+(response-1)*(tileW+hgap),bottom+(10-point)*(tileH+vgap),tileW,tileH];
        ax=axes(f,'Position',pos);hold(ax,'on');box(ax,'on');
        observed=double(s.observations{point}(:,response));
        predicted=double(s.predictions{point}(:,response));
        rows=perOutput.output_column==output & ~perOutput.constant;
        metricBackground='w';
        if range(observed)<=1e-12
            axis(ax,[0 1 0 1]);
            set(ax,'Color',[.88 .88 .88],'XTick',[],'YTick',[]);
            text(ax,.5,.5,'Constant reference','HorizontalAlignment','center', ...
                'VerticalAlignment','middle','FontName','Arial','FontSize',7.5, ...
                'Color',[.30 .30 .30]);
            metricLabel='R^2=NA';
            metricBackground=[.88 .88 .88];
        else
            count=max(1,round(.25*numel(observed)));take=randperm(numel(observed),count);
            combined=[observed;predicted];high=prctile(combined,99.5);
            if ~isfinite(high)||high<=0,high=max(combined);end
            high=1.04*max(high,eps);
            plot(ax,observed(take),predicted(take),'.','Color',pointColor,'MarkerSize',3.0);
            plot(ax,[0 high],[0 high],'k--','LineWidth',1.25);
            plot(ax,[0 high/2],[0 high],':','Color',blue,'LineWidth',1.0);
            plot(ax,[0 high],[0 high/2],':','Color',green,'LineWidth',1.0);
            axis(ax,[0 high 0 high]);
            metricLabel=sprintf('R^2=%.2f',mean(perOutput.R2(rows)));
        end
        set(ax,'FontName','Arial','FontSize',7.5,'TickLength',[.035 .035]);
        if response==1
            ylabel(ax,sprintf('P%d',point),'FontSize',10,'FontWeight','bold');
        end
        annotation(f,'textbox',[pos(1)+tileW-.068 pos(2)+tileH-.020 .066 .014], ...
            'String',metricLabel,'EdgeColor','none','BackgroundColor',metricBackground,'Margin',.1, ...
            'HorizontalAlignment','right','VerticalAlignment','middle','FontName','Arial','FontSize',7.25);
    end
end
for response=1:7
    x=left+(response-1)*(tileW+hgap);
    annotation(f,'textbox',[x .963 tileW .022], ...
        'String',sprintf('%s %s',symbols{response},units{response}), ...
        'Interpreter','tex','EdgeColor','none','HorizontalAlignment','center', ...
        'FontName','Arial','FontSize',11,'FontWeight','bold');
end
annotation(f,'textbox',[left,.004,1-left-right,.029],'String','FLAC2D reference', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',16,'FontName','Arial');
labelAxes=axes(f,'Position',[0 0 1 1],'Visible','off','HitTest','off');
text(labelAxes,.020,bottom+(1-bottom-top)/2,'Point-wise FMRVR prediction', ...
    'Rotation',90,'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontSize',16,'FontName','Arial');
drawnow;
exportgraphics(f,fullfile(outputDir,'task4_all70_observed_predicted.png'),'Resolution',300);
exportgraphics(f,fullfile(outputDir,'task4_all70_observed_predicted.pdf'),'ContentType','image');
close(f);
end
