function path = generate_task4_taylor_diagram(outputDir)
%GENERATE_TASK4_TAYLOR_DIAGRAM Normalized Taylor diagram for outer split 1.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task4;cfg=task4_config(root);
if nargin<1||isempty(outputDir),outputDir=fullfile(cfg.output_root,'pointwise_fmrvr');end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
s=load(fullfile(cfg.results_dir,'scale_aware','production','pointwise_fmrvr_split1.mat'),'splitOne');s=s.splitOne;
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{\rm pore}','\delta\gamma','\delta\nu_s'};
colors=lines(7);f=figure('Visible','off','Color','w','Position',[100 100 900 660]);
ax=axes(f,'Position',[.10 .18 .78 .75]);hold(ax,'on');axis(ax,'equal');
draw_reference(ax);
for response=1:7
    x=[];y=[];
    for point=1:10
        obs=double(s.observations{point}(:,response));pred=double(s.predictions{point}(:,response));
        if range(obs)<=1e-12,continue;end
        rho=corr(obs,pred,'Rows','complete');ratio=std(pred)/std(obs);
        x(end+1)=ratio*rho;y(end+1)=ratio*sqrt(max(0,1-rho^2)); %#ok<AGROW>
    end
    scatter(ax,x,y,46,colors(response,:),'filled','MarkerEdgeColor','w', ...
        'LineWidth',.65, ...
        'DisplayName',symbols{response});
end
xlabel(ax,'Normalized standard deviation');
xlim(ax,[0 1.62]);ylim(ax,[0 1.16]);
set(ax,'FontName','Arial','FontSize',10.5,'TickDir','out','YTick',[], ...
    'Box','off','XGrid','off','YGrid','off','LineWidth',.8);
legend(ax,'Location','southoutside','NumColumns',4,'Interpreter','tex', ...
    'Box','off','FontSize',10);
path=fullfile(outputDir,'task4_taylor_diagram.png');exportgraphics(f,path,'Resolution',300);
exportgraphics(f,fullfile(outputDir,'task4_taylor_diagram.pdf'),'ContentType','vector');close(f);
end

function draw_reference(ax)
theta=linspace(0,pi/2,240);
outerRadius=1.5;
for radius=[.5 1 1.5]
    plot(ax,radius*cos(theta),radius*sin(theta),'-','Color',[.82 .82 .82], ...
        'LineWidth',.65,'HandleVisibility','off');
end
correlations=[.7 .8 .9 .95 .99 1];
for rho=correlations
    angle=acos(rho);
    plot(ax,[0 outerRadius*cos(angle)],[0 outerRadius*sin(angle)],':', ...
        'Color',[.78 .78 .78],'LineWidth',.65,'HandleVisibility','off');
    if rho>0
        text(ax,1.535*cos(angle),1.535*sin(angle),sprintf('%.2g',rho), ...
            'FontName','Arial','FontSize',8.5,'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','Rotation',angle*180/pi-90,'Color',[.25 .25 .25]);
    end
end
% Centered-RMS-difference contours around the unit reference point.
phi=linspace(0,pi,300);
for rmsd=[.25 .5 .75]
    xx=1+rmsd*cos(phi);yy=rmsd*sin(phi);keep=xx>=0 & hypot(xx,yy)<=outerRadius;
    plot(ax,xx(keep),yy(keep),'--','Color',[.66 .66 .66],'LineWidth',.6, ...
        'HandleVisibility','off');
end
text(ax,.24,1.05,'Correlation coefficient','FontName','Arial','FontSize',10, ...
    'FontWeight','bold','Rotation',-22,'Color',[.20 .20 .20]);
plot(ax,1,0,'p','Color','k','MarkerFaceColor',[1 .75 0],'MarkerSize',12, ...
    'LineWidth',.8,'DisplayName','FLAC2D reference');
end
