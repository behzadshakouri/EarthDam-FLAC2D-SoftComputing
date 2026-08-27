clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs\';
FoS='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\FoS (paper-revision-final)\';
Figs='E:\University\My Thesis\BAP project\Papers\1-Journal paper _ Under review\CG\Submitted Files\Revision\Figs\';


%------------------Input Matrix Generation-------------------------------
cd(FoS);
load FoS_results5.mat
FoS='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\FoS (paper-revision-final)\';

for nsample=200 %[50 100 150 200 300 400 500]
    
%-----------------Reading input files--------------------
    
Comment='FoS';
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';

Resl{1,1}='\delta_x';
Resl{1,2}='\delta_y';
Resl{1,3}='\sigma_{xx}';
Resl{1,4}='\sigma_{yy}';


% for a=1:4 %methods
%     
% if a==1

    wposX=100; wposY = 100;
    Length = 700;
    Width = 2400;
    FoSregplot=figure('DefaultAxesFontSize',16,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    FoSregplotTitle=['Fig 17, regplot for FoS & nsample ' num2str(nsample)];
    hold on
    %     fig=figure('DefaultAxesFontSize',12);
    
    
    subplot(1,4,1)
    a1='ELM';
    FDM_ELM_FoSdata=readmatrix([a1 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    p1=plot(FDM_ELM_FoSdata(:,19),FDM_ELM_FoSdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p1(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = ['ELM FoS & n' num2str(nsample)];
    xlabel('Calculated FoS by FDM','FontSize',14);
    ylabel('Predicted FoS by ELM','FontSize',14);
    xlim([0.95 1.4]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM');
%     saveas(fig,[figname '.png']);
%     close


    subplot(1,4,2)
    a2='ELMABC';
    FDM_ELMABC_FoSdata=readmatrix([a2 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    p2=plot(FDM_ELMABC_FoSdata(:,19),FDM_ELMABC_FoSdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p2(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = ['ELM FoS & n' num2str(nsample)];
    xlabel('Calculated FoS by FDM','FontSize',14);
    ylabel('Predicted FoS by ELM-ABC','FontSize',14);
    xlim([0.95 1.4]);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-ABC');
%     saveas(fig,[figname '.png']);
%     close

    subplot(1,4,3)
    a3='ELMACOR';
    FDM_ELMACOR_FoSdata=readmatrix([a3 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    p3=plot(FDM_ELMACOR_FoSdata(:,19),FDM_ELMACOR_FoSdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p3(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = ['ELM FoS & n' num2str(nsample)];
    xlabel('Calculated FoS by FDM','FontSize',14);
    ylabel('Predicted FoS by ELM-ACOR','FontSize',14);
    xlim([0.95 1.4]);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-ACOR');
%     saveas(fig,[figname '.png']);
%     close

    subplot(1,4,4)
    a4='ELMIGWO';
    FDM_ELMIGWO_FoSdata=readmatrix([a4 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    p4=plot(FDM_ELMIGWO_FoSdata(:,19),FDM_ELMIGWO_FoSdata(:,20),'ko','LineWidth',1.25,'MarkerSize',6);
    p4(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
%     figname = ['ELM FoS & n' num2str(nsample)];
    xlabel('Calculated FoS by FDM','FontSize',14);
    ylabel('Predicted FoS by ELM-IGWO','FontSize',14);
    xlim([0.95 1.4]);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',14);
    hline = refline;
    hline.LineWidth = 2;
    hline.Color = 'k';
    legend('FDM--ELM-IGWO');
    
    
    cd(Figs)

    saveas(FoSregplot,[FoSregplotTitle '.png']);
    close
    
end