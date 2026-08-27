clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';
Figs='E:\University\My Thesis\BAP project\Papers\1-Journal paper _ Under review\CG\Submitted Files\Revision\Figs\';


%------------------Input Matrix Generation-------------------------------
cd(Results);
load results5.mat
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';

for nsample=200 %[50 100 150 200 300 400 500]
    
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
Resl{1,1}='\delta_x';
Resl{1,2}='\delta_y';
Resl{1,3}='\sigma_{xx}';
Resl{1,4}='\sigma_{yy}';

for i=3:3 %1:numel(node_row) %node numbers

for a=1:4 %methods
    
% for j=1:4 %responses

    
Comment=['QOI_' num2str(i) '_' Res{1,j}];
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';

QOIn=[QOIs 'QOI_' num2str(i)];


if a==1
    a1='ELM';
    cd([QOIn '\n' num2str(nsample) '\']);
    j=1; %responses
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    wposX=100; wposY = 100;
    Length = 700;
    Width = 2400;
    FigA1=figure('DefaultAxesFontSize',16,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    FigA1Title=['Fig A1, regplot for ' a1 ', QoI ' num2str(i) ' & nsample ' num2str(nsample)];
    hold on
    
    subplot(1,4,1)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a1 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
    ylabel('Predicted by ELM','FontSize',14);
    xlim([0.05 0.3]);
    ylim([0.05 0.3]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close



    j=2; %responses
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,2)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a1 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];[' by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a1],'FontSize',14);
    xlim([-0.48 -0.15]);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=3; %responses
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,3)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a1 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a1],'FontSize',14);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=4; %responses
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,4)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a1 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a1],'FontSize',14);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
    cd(Figs);
    saveas(FigA1,[FigA1Title '.png']);
    close


elseif a==2
    a2='ELMABC';
    cd([QOIn '\n' num2str(nsample) '\']);
    j=1; %responses
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    wposX=100; wposY = 100;
    Length = 600;
    Width = 2400;
    FigA2=figure('DefaultAxesFontSize',16,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    FigA2Title=['Fig A2, regplot for ' a2 ', QoI ' num2str(i) ' & nsample ' num2str(nsample)];
    hold on
    
    subplot(1,4,1)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a2 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
    ylabel('Predicted by ELM-ABC','FontSize',14);
    xlim([0.05 0.3]);
    ylim([0.05 0.3]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-ABC');
%     saveas(fig,[figname '.png']);
%     close



    j=2; %responses
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,2)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a2 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];[' by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel('Predicted by ' a2],'FontSize',14);
    xlim([-0.48 -0.15]);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=3; %responses
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,3)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a2 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel('Predicted by ' a2],'FontSize',14);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=4; %responses
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,4)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a2 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel('Predicted by ' a2],'FontSize',14);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
    cd(Figs);
    saveas(FigA2,[FigA2Title '.png']);
    close
    
    
elseif a==3
    a3='ELMACOR';
    cd([QOIn '\n' num2str(nsample) '\']);
    j=1; %responses
    FDM_ELMdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    wposX=100; wposY = 100;
    Length = 600;
    Width = 2400;
    FigA3=figure('DefaultAxesFontSize',16,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    FigA3Title=['Fig A3, regplot for ' a3 ', QoI ' num2str(i) ' & nsample ' num2str(nsample)];
    hold on
    
    subplot(1,4,1)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a3 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
    ylabel('Predicted by ELM-ACOR','FontSize',14);
    xlim([0.05 0.3]);
    ylim([0.05 0.3]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-ACOR');
%     saveas(fig,[figname '.png']);
%     close



    j=2; %responses
    FDM_ELMdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,2)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a3 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];[' by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a3],'FontSize',14);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    xlim([-0.48 -0.15]);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=3; %responses
    FDM_ELMdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,3)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a3 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a3],'FontSize',14);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=4; %responses
    FDM_ELMdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,4)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a3 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a3],'FontSize',14);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
    cd(Figs);
    saveas(FigA3,[FigA3Title '.png']);
    close
    
    
elseif a==4
    a4='ELMIGWO';
    cd([QOIn '\n' num2str(nsample) '\']);
    j=1; %responses
    FDM_ELMdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    wposX=100; wposY = 100;
    Length = 700;
    Width = 2400;
    Fig15=figure('DefaultAxesFontSize',16,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    Fig15Title=['Fig 15, regplot for ' a4 ', QoI ' num2str(i) ' & nsample ' num2str(nsample)];
    hold on
    
    subplot(1,4,1)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a4 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
    ylabel('Predicted by ELM-IGWO','FontSize',14);
    xlim([0.05 0.3]);
    ylim([0.05 0.3]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-IGWO');
%     saveas(fig,[figname '.png']);
%     close



    j=2; %responses
    FDM_ELMdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,2)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a4 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];[' by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a4],'FontSize',14);
    xlim([-0.48 -0.15]);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=3; %responses
    FDM_ELMdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,3)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a4 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a4],'FontSize',14);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close

    j=4; %responses
    FDM_ELMdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);

    subplot(1,4,4)
        
%     fig=figure('DefaultAxesFontSize',12);
    p=plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = [a4 ' Res{1,j} ' for QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel({['Calculated ' Resl{1,j}];['by FDM ' Unit{1,j}]},'FontSize',14);
%     ylabel(['Predicted by ' a4],'FontSize',14);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    axis equal;
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
%     legend('FDM--ELM');
    cd(Figs);
    saveas(Fig15,[Fig15Title '.png']);
    close

end

% end

end
end
end