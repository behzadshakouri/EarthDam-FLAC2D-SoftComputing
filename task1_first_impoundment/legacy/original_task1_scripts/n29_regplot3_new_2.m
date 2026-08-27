clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';


%------------------Input Matrix Generation-------------------------------
cd(Results);
load results5.mat
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';

for nsample=[50 100 150 200 300 400 500]
    
%-----------------Reading input files--------------------
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';
Unit{1,1}='[m]';
Unit{1,2}='[m]';
Unit{1,3}='[Pa]';
Unit{1,4}='[Pa]';

for i=1:numel(node_row) %node numbers

for j=1:4 %responses
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';

QOIn=[QOIs 'QOI_' num2str(i)];
cd([QOIn '\n' num2str(nsample) '\']);

for a=1:4 %methods
    
if a==1
    a1='ELM';
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
    figname = ['ELM ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel(['Calculated ' Res{1,j} ' by FDM ' Unit{1,j}],'FontSize',14);
    ylabel(['Predicted ' Res{1,j} ' by ELM ' Unit{1,j}],'FontSize',14);
    title(figname,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     N=size(FDM_ELMdata(:,19),1);
%     mu=mean(FDM_ELMdata(:,19));
%     STD=std(FDM_ELMdata(:,19));
%     SEM=STD/sqrt(N);
%     ME=10*SEM;
%     ub=FDM_ELMdata(:,19)+ME;
%     lb=FDM_ELMdata(:,19)-ME;
%     p2=plot(FDM_ELMdata(:,19),ub);
%     p3=plot(FDM_ELMdata(:,19),lb);
%     X=[0.9*min(FDM_ELMdata(:,19)), 1.1*max(FDM_ELMdata(:,19))];
%     Y=[0.9*min(FDM_ELMdata(:,19)), 1.1*max(FDM_ELMdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM');
    saveas(fig,[figname '.png']);
    close
elseif a==2
    a2='ELMABC';
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    figname = ['ELM-ABC ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM ' Unit{1,j}],'FontSize',14);
    ylabel(['Predicted ' Res{1,j} ' by ELM-ABC ' Unit{1,j}],'FontSize',14);
    title(figname,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMABCdata(:,19)), 1.1*max(FDM_ELMABCdata(:,19))];
%     Y=[0.9*min(FDM_ELMABCdata(:,19)), 1.1*max(FDM_ELMABCdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ABC');
    saveas(fig,[figname '.png']);
    close
elseif a==3
    a3='ELMACOR';
    FDM_ELMACORdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMACORdata(:,19),FDM_ELMACORdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    figname = ['ELM-ACOR ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM ' Unit{1,j}],'FontSize',14);
    ylabel(['Predicted ' Res{1,j} ' by ELM-ACOR ' Unit{1,j}],'FontSize',14);
    title(figname,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMACORdata(:,19)), 1.1*max(FDM_ELMACORdata(:,19))];
%     Y=[0.9*min(FDM_ELMACORdata(:,19)), 1.1*max(FDM_ELMACORdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ACOR');
    saveas(fig,[figname '.png']);
    close
elseif a==4
    a4='ELMIGWO';
    FDM_ELMIGWOdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMIGWOdata(:,19),FDM_ELMIGWOdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    figname = ['ELM-IGWO ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM ' Unit{1,j}],'FontSize',14);
    ylabel(['Predicted ' Res{1,j} ' by ELM-IGWO ' Unit{1,j}],'FontSize',14);
    title(figname,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMIGWOdata(:,19)), 1.1*max(FDM_ELMIGWOdata(:,19))];
%     Y=[0.9*min(FDM_ELMIGWOdata(:,19)), 1.1*max(FDM_ELMIGWOdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-IGWO');
    saveas(fig,[figname '.png']);
    close
end

end

end
end
end