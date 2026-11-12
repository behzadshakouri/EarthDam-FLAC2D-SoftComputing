function path = generate_task3_taylor_diagram(outputDir)
%GENERATE_TASK3_TAYLOR_DIAGRAM Normalized Taylor diagram for outer split 1.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task3;cfg=task3_config(root);
if nargin<1||isempty(outputDir),outputDir=fullfile(cfg.output_root,'compact_pointwise_fmrvr');end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
s=load(fullfile(cfg.results_root,'compact_pointwise_fmrvr','split1.mat'),'splitOne');s=s.splitOne;
symbols={'\Delta_x','\Delta_y','\sigma_{xx}','\sigma_{yy}','P_{\rm pore}','\delta\gamma','\delta\nu_s'};
colors=lines(7);f=figure('Visible','off','Color','w','Position',[100 100 760 650]);ax=axes(f);hold(ax,'on');axis(ax,'equal');
draw_reference(ax);
for response=1:7
    x=[];y=[];
    for point=1:10
        col=(point-1)*7+response;obs=double(s.observed(:,col));pred=double(s.prediction(:,col));
        if range(obs)<=1e-12,continue;end
        rho=corr(obs,pred,'Rows','complete');ratio=std(pred)/std(obs);
        x(end+1)=ratio*rho;y(end+1)=ratio*sqrt(max(0,1-rho^2)); %#ok<AGROW>
    end
    scatter(ax,x,y,48,colors(response,:),'filled','MarkerEdgeColor','k', ...
        'DisplayName',symbols{response});
end
xlabel(ax,'Normalized standard deviation \times correlation');ylabel(ax,'Normalized standard deviation component');
legend(ax,'Location','southoutside','Orientation','horizontal','Interpreter','tex','NumColumns',4);xlim(ax,[0 1.6]);ylim(ax,[0 1.15]);grid(ax,'on');box(ax,'on');
set(ax,'FontName','Arial','FontSize',10,'TickDir','out');
path=fullfile(outputDir,'task3_taylor_diagram.png');exportgraphics(f,path,'Resolution',300);
exportgraphics(f,fullfile(outputDir,'task3_taylor_diagram.pdf'),'ContentType','vector');close(f);
end

function draw_reference(ax)
theta=linspace(0,pi/2,240);
for radius=[.5 1 1.5],plot(ax,radius*cos(theta),radius*sin(theta),':','Color',[.72 .72 .72],'HandleVisibility','off');end
for rho=[.5 .7 .8 .9 .95]
    angle=acos(rho);plot(ax,[0 1.55*cos(angle)],[0 1.55*sin(angle)],':','Color',[.82 .82 .82],'HandleVisibility','off');
end
plot(ax,1,0,'kp','MarkerFaceColor',[1 .75 0],'MarkerSize',12,'DisplayName','FLAC2D reference');
end
