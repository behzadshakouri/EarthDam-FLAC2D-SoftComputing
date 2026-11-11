function generate_task3_compact_fmrvr_figures(outputDir)
%GENERATE_TASK3_COMPACT_FMRVR_FIGURES Final point-wise FMRVR paper figures.
analysisDir=fileparts(mfilename('fullpath'));root=fileparts(analysisDir);addpath(root);setup_task3;
cfg=task3_config(root);
if nargin<1||isempty(outputDir),outputDir=fullfile(cfg.output_root,'compact_pointwise_fmrvr');end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
resultsDir=fullfile(cfg.results_root,'compact_pointwise_fmrvr');
outer=readtable(fullfile(resultsDir,'outer_metrics.csv'));
perOutput=readtable(fullfile(resultsDir,'per_output.csv'));
family=readtable(fullfile(resultsDir,'response_summary.csv'));
saved=load(fullfile(resultsDir,'split1.mat'),'splitOne');s=saved.splitOne;
dictionary=task3_response_dictionary();symbols={'\Delta_x','\Delta_y','\sigma_{xx}', ...
    '\sigma_{yy}','P_{\rm pore}','\delta\gamma','\delta\nu_s'};
blue=[0 .447 .741];orange=[.85 .325 .098];green=[.18 .58 .32];

f=figure('Visible','off','Color','w','Position',[100 100 900 480]);
plot(outer.repeat,outer.mean_R2,'-o','Color',blue,'LineWidth',1.8, ...
    'MarkerSize',6,'MarkerFaceColor','w','DisplayName','Mean over outputs');hold on;
plot(outer.repeat,outer.median_R2,'-s','Color',orange,'LineWidth',1.8, ...
    'MarkerSize',6,'MarkerFaceColor','w','DisplayName','Median over outputs');
yline(.8,':','R^2=0.80','LabelHorizontalAlignment','left','LineWidth',1.0, ...
    'HandleVisibility','off');grid on;
xlim([1 10]);ylim([.78 .92]);xticks(1:10);
xlabel('Outer split');ylabel('Held-out R^2');
legend('Location','southoutside','Orientation','horizontal','Box','off');
set(gca,'FontName','Arial','FontSize',10.5,'TickDir','out','LineWidth',.8, ...
    'GridAlpha',.16,'MinorGridAlpha',.10);
export_pair(f,outputDir,'time_resolved_nested_validation');close(f);

f=figure('Visible','off','Color','w','Position',[100 100 930 470]);
familyStd=zeros(7,1);
for response=1:7
    splitMeans=zeros(numel(unique(perOutput.repeat)),1);
    for repeat=1:numel(splitMeans)
        rows=perOutput.repeat==repeat & perOutput.response==response & ~perOutput.constant;
        splitMeans(repeat)=mean(perOutput.R2(rows));
    end
    familyStd(response)=std(splitMeans);
end
bar(family.mean_R2,'FaceColor',blue);hold on;
errorbar(1:7,family.mean_R2,familyStd,'k.','LineWidth',1.1,'CapSize',8);
yline(.8,':');grid on;ylim([.76 .92]);
set(gca,'XTick',1:7,'XTickLabel',symbols,'TickLabelInterpreter','tex','FontSize',10);
ylabel('Mean held-out R^2');title('Predictive performance by response family');
export_pair(f,outputDir,'time_resolved_family_performance');close(f);

map=nan(7,10);
for output=1:70
    rows=perOutput.output_column==output & ~perOutput.constant;
    if any(rows),map(dictionary(output).response,dictionary(output).point)=mean(perOutput.R2(rows));end
end
f=figure('Visible','off','Color','w','Position',[100 100 1050 450]);
h=imagesc(map);set(h,'AlphaData',~isnan(map));set(gca,'Color',[.88 .88 .88]);
finiteMap=map(isfinite(map));caxis([floor(20*min(finiteMap))/20 ceil(20*max(finiteMap))/20]);colorbar;
set(gca,'XTick',1:10,'YTick',1:7,'YTickLabel',symbols,'TickLabelInterpreter','tex');
xlabel('Response-extraction point');ylabel('Response');title('Mean held-out R^2 over ten record-level splits');
for r=1:7,for p=1:10,if isfinite(map(r,p)),text(p,r,sprintf('%.2f',map(r,p)), ...
            'HorizontalAlignment','center','FontSize',8,'Color',map(r,p)<.72*[1 1 1]);end,end,end
export_pair(f,outputDir,'time_resolved_output_map');close(f);

% Task 2-style all-70 observed-versus-predicted grid. Manual axes retain
% large, nearly square panels instead of shrinking them inside a wide tile.
plot_all70_task2_style(s,perOutput,symbols,[.10 .43 .70],blue,green,outputDir);

ids=unique(s.record_id(isfinite(s.record_id)),'stable');demand=zeros(numel(ids),1);
for k=1:numel(ids),demand(k)=mean(s.observed(s.record_id==ids(k),:),'all');end
[~,order]=sort(demand,'descend');base=[1,ceil(numel(ids)/2)];
largest=order(find(~ismember(order,base),1,'first'));chosen=ids([base,largest]);point=6;
f=figure('Visible','off','Color','w','Position',[50 50 1180 1320]);
t=tiledlayout(7,3,'TileSpacing','compact','Padding','compact');
units={'m','m','Pa','Pa','Pa','--','--'};firstAx=[];referenceHandle=[];predictionHandle=[];
for response=1:7
    output=(point-1)*7+response;
    for column=1:3
        ax=nexttile(t);take=s.record_id==chosen(column);
        h1=plot(ax,s.time_s(take),s.observed(take,output),'k-','LineWidth',1.35);hold(ax,'on');
        h2=plot(ax,s.time_s(take),s.prediction(take,output),'-','Color',orange,'LineWidth',1.35);grid(ax,'on');
        if isempty(firstAx),firstAx=ax;referenceHandle=h1;predictionHandle=h2;end
        if response==1,title(ax,sprintf('Record %d',chosen(column)),'FontSize',11,'FontWeight','bold');end
        if column==1
            ylabel(ax,sprintf('%s (%s)',symbols{response},units{response}), ...
                'Interpreter','tex','FontSize',10.5);
        end
        if response==7,xlabel(ax,'Time (s)');end
        set(ax,'FontName','Arial','FontSize',8.5,'TickDir','out','LineWidth',.7, ...
            'GridAlpha',.14,'MinorGridAlpha',.08);
    end
end
legend(firstAx,[referenceHandle predictionHandle],{'FLAC2D reference','FMRVR prediction'}, ...
    'Orientation','vertical','Location','northwest','Box','off','FontSize',8.5);
export_pair(f,outputDir,'time_resolved_representative_histories');close(f);
end

function export_pair(f,folder,name)
% exportgraphics uses the figure content bounds. Using print -bestfit here
% placed landscape plots in the center of a letter-size PDF and created large
% invisible margins when the files were included in the manuscript.
exportgraphics(f,fullfile(folder,[name '.pdf']),'ContentType','vector');
exportgraphics(f,fullfile(folder,[name '_crop.pdf']),'ContentType','vector');
exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300);
end

function plot_all70_task2_style(s,perOutput,symbols,pointColor,blue,green,outputDir)
rng(1);
f=figure('Visible','off','Color','w','Renderer','opengl','Position',[20 20 1600 1133]);
left=.075;right=.018;bottom=.075;top=.035;hgap=.012;vgap=.025;
tileW=(1-left-right-9*hgap)/10;tileH=(1-bottom-top-6*vgap)/7;
units={'[m]','[m]','[Pa]','[Pa]','[Pa]','[-]','[-]'};
for response=1:7
    for point=1:10
        output=(point-1)*7+response;
        pos=[left+(point-1)*(tileW+hgap),bottom+(7-response)*(tileH+vgap),tileW,tileH];
        ax=axes(f,'Position',pos);hold(ax,'on');box(ax,'on');
        observed=double(s.observed(:,output));predicted=double(s.prediction(:,output));
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
            count=max(1,round(.33*numel(observed)));take=randperm(numel(observed),count);
            combined=[observed;predicted];high=prctile(combined,99.5);
            if ~isfinite(high)||high<=0,high=max(combined);end
            high=1.04*max(high,eps);
            plot(ax,observed(take),predicted(take),'.','Color',pointColor,'MarkerSize',3.2);
            plot(ax,[0 high],[0 high],'k--','LineWidth',1.25);
            plot(ax,[0 high/2],[0 high],':','Color',blue,'LineWidth',1.0);
            plot(ax,[0 high],[0 high/2],':','Color',green,'LineWidth',1.0);
            axis(ax,[0 high 0 high]);axis(ax,'square');
            metricLabel=sprintf('R^2=%.2f',mean(perOutput.R2(rows)));
        end
        set(ax,'FontName','Arial','FontSize',7.5,'TickLength',[.035 .035], ...
            'XTickMode','auto','YTickMode','auto');
        if response==1,title(ax,sprintf('P%d',point),'FontSize',11,'FontWeight','bold');end
        if point==1
            ylabel(ax,sprintf('%s %s',symbols{response},units{response}), ...
                'Interpreter','tex','FontSize',11,'FontWeight','bold');
        end
        annotation(f,'textbox',[pos(1)+tileW-.047 pos(2)+tileH-.030 .045 .016], ...
            'String',metricLabel,'EdgeColor','none','BackgroundColor',metricBackground,'Margin',.1, ...
            'HorizontalAlignment','right','VerticalAlignment','middle','FontName','Arial','FontSize',7.25);
    end
end
annotation(f,'textbox',[left,.012,1-left-right,.035],'String','FLAC2D reference', ...
    'EdgeColor','none','HorizontalAlignment','center','FontSize',16,'FontName','Arial');
labelAxes=axes(f,'Position',[0 0 1 1],'Visible','off','HitTest','off');
text(labelAxes,.018,bottom+(1-bottom-top)/2,'Point-wise FMRVR prediction', ...
    'Rotation',90,'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontSize',16,'FontName','Arial');
drawnow;
exportgraphics(f,fullfile(outputDir,'time_resolved_all70_observed_predicted.png'),'Resolution',300);
exportgraphics(f,fullfile(outputDir,'time_resolved_all70_observed_predicted.pdf'),'ContentType','image');
close(f);
end
