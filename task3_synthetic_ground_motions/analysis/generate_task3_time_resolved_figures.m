function generate_task3_time_resolved_figures()
%GENERATE_TASK3_TIME_RESOLVED_FIGURES Publication figures for final workflow.
analysisDir=fileparts(mfilename('fullpath')); root=fileparts(analysisDir); addpath(root); setup_task3;
cfg=task3_config(root); resultsDir=cfg.analysis_results_dir; figuresDir=fullfile(cfg.output_root,'figures');
if ~exist(figuresDir,'dir'), mkdir(figuresDir); end
metrics=readtable(fullfile(resultsDir,'time_resolved_residual_fmrvr_family_metrics_100points.csv'));
family=readtable(fullfile(resultsDir,'time_resolved_residual_fmrvr_response_family_100points.csv'));
perOutput=readtable(fullfile(resultsDir,'time_resolved_residual_fmrvr_per_output_100points.csv'));
saved=load(fullfile(resultsDir,'time_resolved_residual_fmrvr_split1_100points.mat'),'splitOne'); s=saved.splitOne;
dictionary=task3_response_dictionary(); symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{pore}','\delta\gamma','\delta\nu_s'};
blue=[0 .4470 .7410]; orange=[.8500 .3250 .0980];

f=figure('Visible','off','Color','w','Position',[100 100 820 460]);
plot(metrics.repeat,metrics.ridge_mean_R2,'-o','Color',blue,'LineWidth',1.6,'MarkerFaceColor',blue); hold on;
plot(metrics.repeat,metrics.corrected_mean_R2,'-s','Color',orange,'LineWidth',1.6,'MarkerFaceColor',orange);
yline(.8,':','R^2=0.80','LabelHorizontalAlignment','left'); grid on; ylim([.76 .88]);
xlabel('Outer split'); ylabel('Mean held-out R^2');
legend('Cumulative ridge','Ridge + residual FMRVR','Location','southeast');
title('Record-separated repeated validation'); export_both(f,figuresDir,'time_resolved_nested_validation'); close(f);

f=figure('Visible','off','Color','w','Position',[100 100 930 470]);
b=bar([family.ridge_mean_R2 family.corrected_mean_R2],'grouped'); b(1).FaceColor=blue; b(2).FaceColor=orange;
hold on; errorbar(b(2).XEndPoints,family.corrected_mean_R2,family.corrected_sd_R2, ...
    'k.','LineWidth',1.0,'CapSize',6); yline(.8,':'); grid on; ylim([.72 .91]);
set(gca,'XTick',1:7,'XTickLabel',symbols,'TickLabelInterpreter','tex','FontSize',10);
ylabel('Mean held-out R^2'); legend('Cumulative ridge','Ridge + residual FMRVR','Location','southoutside','Orientation','horizontal');
title('Predictive performance by response family'); export_both(f,figuresDir,'time_resolved_family_performance'); close(f);

map=nan(7,10); gain=nan(7,10);
for output=1:70
    rows=perOutput.output_column==output & ~perOutput.constant;
    if any(rows)
        map(dictionary(output).response,dictionary(output).point)=mean(perOutput.corrected_R2(rows));
        gain(dictionary(output).response,dictionary(output).point)=mean(perOutput.delta_R2(rows));
    end
end
f=figure('Visible','off','Color','w','Position',[100 100 1050 670]);
subplot(2,1,1); h=imagesc(map); set(h,'AlphaData',~isnan(map)); set(gca,'Color',[.88 .88 .88]); caxis([.55 .95]); colorbar;
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Monitoring point'); ylabel('Response'); title('Mean held-out R^2');
subplot(2,1,2); h=imagesc(gain); set(h,'AlphaData',~isnan(gain)); set(gca,'Color',[.88 .88 .88]);
limit=max(abs(gain(:)),[],'omitnan'); caxis([-limit limit]); colorbar;
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Monitoring point'); ylabel('Response'); title('Mean R^2 gain from residual FMRVR');
export_both(f,figuresDir,'time_resolved_output_map'); close(f);

% Task 2-style all-70 diagnostic. Points are from outer split 1; panel R2
% annotations are the means across all ten outer splits.
rowLabels={'\Delta_x [m]','\Delta_y [m]','\sigma_{xx} [Pa]','\sigma_{yy} [Pa]', ...
    'P_{pore} [Pa]','\delta\gamma [-]','\delta\nu_s [-]'};
f=figure('Visible','off','Color','w','Renderer','opengl','Position',[20 20 9000 9000]);
drawnow; figPos=get(f,'Position'); figW=figPos(3); figH=figPos(4);
leftMargin=.055; rightMargin=.025; bottomMargin=.100; topMargin=.035;
hGap=.016; vGap=.036;
availableWidth=1-leftMargin-rightMargin-9*hGap;
availableHeight=1-bottomMargin-topMargin-6*vGap;
tilePixels=min((availableWidth*figW)/10,(availableHeight*figH)/7);
tileWidth=tilePixels/figW; tileHeight=tilePixels/figH;
usedWidth=10*tileWidth+9*hGap; usedHeight=7*tileHeight+6*vGap;
rng(1);
for response=1:7
  for point=1:10
    output=(point-1)*7+response;
    left=leftMargin+(point-1)*(tileWidth+hGap);
    bottom=bottomMargin+(7-response)*(tileHeight+vGap);
    ax=axes(f,'Position',[left bottom tileWidth tileHeight]); hold(ax,'on'); box(ax,'on');
    set(ax,'FontName','Arial','FontSize',8,'TickLength',[.035 .035]);
    observed=s.observed(:,output); predicted=s.corrected_prediction(:,output);
    if range(observed)<=1e-12
        xlim(ax,[0 1]); ylim(ax,[0 1]); axis(ax,'square');
        ax.XTick=[0 .5 1]; ax.YTick=[0 .5 1];
        text(ax,.03,.97,'R^2=NA','Units','normalized','VerticalAlignment','top', ...
            'HorizontalAlignment','left','FontSize',8,'BackgroundColor','w','Margin',.5);
    else
        [xmin,xmax,ymin,ymax]=task2_limits(observed,predicted);
        xlim(ax,[xmin xmax]); ylim(ax,[ymin ymax]); axis(ax,'square');
        ax.XTick=task2_ensure_ticks(task2_smart_ticks(xmin,xmax,3),xmin,xmax,3);
        ax.YTick=task2_ensure_ticks(task2_smart_ticks(ymin,ymax,3),ymin,ymax,3);
        ax.XAxis.Exponent=0; ax.YAxis.Exponent=0;
        [xLabels,xExponent]=task2_compact_labels(ax.XTick,2);
        [yLabels,yExponent]=task2_compact_labels(ax.YTick,2);
        ax.XTickLabel=xLabels; ax.YTickLabel=yLabels;
        xRange=xmax-xmin; yRange=ymax-ymin;
        if ~isempty(xExponent)
            text(ax,xmax,ymin+.035*yRange,sprintf('\\times10^{%d}',xExponent), ...
                'VerticalAlignment','bottom','HorizontalAlignment','right', ...
                'FontSize',7.5,'Interpreter','tex','Clipping','off');
        end
        if ~isempty(yExponent)
            text(ax,xmin+.020*xRange,ymax,sprintf('\\times10^{%d}',yExponent), ...
                'VerticalAlignment','bottom','HorizontalAlignment','left', ...
                'FontSize',7.5,'Interpreter','tex','Clipping','off');
        end
        sampleCount=max(1,round(.33*numel(observed)));
        sampleIndex=randperm(numel(observed),sampleCount);
        plot(ax,observed(sampleIndex),predicted(sampleIndex),'.','Color',orange,'MarkerSize',2.5);
        focusMin=prctile(observed,1); focusMax=prctile(observed,99);
        guideMin=max([xmin,ymin,focusMin]); guideMax=min([xmax,ymax,focusMax]);
        if guideMax>guideMin
            xx=linspace(guideMin,guideMax,120);
            plot(ax,xx,xx,'k--','LineWidth',1.4);
        end
        guideMin=max([xmin,ymin/2,focusMin]); guideMax=min([xmax,ymax/2,focusMax]);
        if guideMax>guideMin
            xx=linspace(guideMin,guideMax,120);
            plot(ax,xx,2*xx,':','Color',blue,'LineWidth',1.1);
        end
        guideMin=max([xmin,2*ymin,focusMin]); guideMax=min([xmax,2*ymax,focusMax]);
        if guideMax>guideMin
            xx=linspace(guideMin,guideMax,120);
            plot(ax,xx,.5*xx,':','Color',[0 .85 .10],'LineWidth',1.1);
        end
        rows=perOutput.output_column==output & ~perOutput.constant;
        meanR2=mean(perOutput.corrected_R2(rows),'omitnan');
        text(ax,.03,.97,sprintf('R^2=%.2f',meanR2),'Units','normalized', ...
            'VerticalAlignment','top','HorizontalAlignment','left','FontSize',8, ...
            'BackgroundColor','w','Margin',.5);
    end
    if response==1
        heading=title(ax,sprintf('P%d',point),'FontSize',12,'FontWeight','bold');
        heading.Units='normalized'; heading.Position(2)=heading.Position(2)-.016;
    end
    if point==1
        rowLabel=ylabel(ax,rowLabels{response},'Interpreter','tex','FontSize',12,'FontWeight','bold');
        rowLabel.Units='normalized'; rowLabel.Position(1)=-.40; rowLabel.Position(2)=.5;
    end
  end
end
annotation(f,'textbox',[leftMargin .045 usedWidth .030],'String','FLAC2D reference', ...
    'EdgeColor','none','HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontName','Arial','FontSize',18);
labelAxes=axes('Parent',f,'Position',[0 0 1 1],'Units','normalized','Visible','off','HitTest','off');
labelAxes.XLim=[0 1]; labelAxes.YLim=[0 1];
text(labelAxes,.013,bottomMargin+usedHeight/2,'Residual FMRVR prediction', ...
    'Rotation',90,'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontName','Arial','FontSize',18);
set(f,'PaperPositionMode','auto');
print(f,fullfile(figuresDir,'time_resolved_all70_observed_predicted.pdf'),'-dpdf','-opengl','-bestfit');
exportgraphics(f,fullfile(figuresDir,'time_resolved_all70_observed_predicted.png'),'Resolution',300); close(f);

% Representative histories: stable, sentinel-bearing, and largest-demand cases.
prepared=load(fullfile(cfg.results_dir,'task3_prepared_dataset.mat'),'qc');
testIds=s.test_ids(:); stable=testIds(~any(prepared.qc.truncated(testIds,:),2)); failed=testIds(any(prepared.qc.truncated(testIds,:),2));
finalDemand=squeeze(mean(s.observed,2)); [~,largestRow]=max(finalDemand); largest=s.realization_id(largestRow);
chosen=[stable(1),failed(1),largest]; point=6;
f=figure('Visible','off','Color','w','Position',[50 50 1150 1500]); layout=tiledlayout(7,3,'TileSpacing','compact','Padding','compact');
for response=1:7
    output=(point-1)*7+response;
    for column=1:3
        nexttile; take=s.realization_id==chosen(column);
        hObserved=plot(s.time_s(take),s.observed(take,output),'k-','LineWidth',1.1); hold on;
        hPredicted=plot(s.time_s(take),s.corrected_prediction(take,output),'-','Color',orange,'LineWidth',1.1); grid on;
        if response==1, title(sprintf('Record %d',chosen(column))); end
        if column==1, ylabel(symbols{response},'Interpreter','tex'); end
        if response==7, xlabel('Time (s)'); end
    end
end
title(layout,sprintf('Representative cumulative response envelopes at P%d',point));
legend([hObserved hPredicted],{'FLAC2D','Prediction'},'Location','southoutside','Orientation','horizontal');
export_both(f,figuresDir,'time_resolved_representative_histories'); close(f);
end

function [xmin,xmax,ymin,ymax]=task2_limits(observed,predicted)
xlo=prctile(observed,.5); xhi=prctile(observed,99.5);
ylo=prctile(predicted,.5); yhi=prctile(predicted,99.5);
xspan=xhi-xlo; yspan=yhi-ylo;
if xspan<=0, xpad=.05*max(abs([xlo xhi 1])); else, xpad=.05*xspan; end
if yspan<=0, ypad=.05*max(abs([ylo yhi 1])); else, ypad=.05*yspan; end
xmin=max(0,xlo-xpad); xmax=xhi+xpad; ymin=max(0,ylo-ypad); ymax=yhi+ypad;
span=max(xmax-xmin,ymax-ymin); cx=.5*(xmin+xmax); cy=.5*(ymin+ymax);
xmin=max(0,cx-span/2); xmax=xmin+span; ymin=max(0,cy-span/2); ymax=ymin+span;
if xmax<=xmin, xmax=xmin+1; end
if ymax<=ymin, ymax=ymin+1; end
end

function ticks=task2_smart_ticks(vmin,vmax,maxTicks)
vmin=max(0,vmin); rawSpan=vmax-vmin; rawStep=rawSpan/max(1,maxTicks-1);
power=10^floor(log10(rawStep)); bases=[1 2 2.5 5 10];
index=find(bases*power>=rawStep/(maxTicks-1),1,'first');
if isempty(index), step=rawStep/max(1,maxTicks-1); else, step=bases(index)*power; end
ticks=ceil(vmin/step)*step:step:floor(vmax/step)*step;
if numel(ticks)<2, ticks=linspace(vmin,vmax,min(maxTicks,3)); end
ticks=unique([vmin ticks vmax]);
if numel(ticks)>maxTicks, ticks=linspace(vmin,vmax,maxTicks); end
end

function ticks=task2_ensure_ticks(ticks,vmin,vmax,targetCount)
ticks=unique(ticks(isfinite(ticks)));
if numel(ticks)<2, ticks=linspace(vmin,vmax,targetCount); end
end

function [labels,exponent]=task2_compact_labels(ticks,threshold)
maximum=max(abs(ticks)); exponent=[];
if maximum==0 || ~isfinite(maximum), labels=cellstr(compose('%.2g',ticks)); return; end
candidate=floor(log10(maximum));
if abs(candidate)<threshold, labels=cellstr(compose('%.2g',ticks)); return; end
exponent=candidate; labels=cellstr(compose('%.2g',ticks/10^exponent));
end

function export_both(f,folder,name)
set(f,'PaperPositionMode','auto');
print(f,fullfile(folder,[name '.pdf']),'-dpdf','-painters','-bestfit');
print(f,fullfile(folder,[name '.png']),'-dpng','-r220');
end
