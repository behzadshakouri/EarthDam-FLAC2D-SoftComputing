clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Figs='E:\University\My Thesis\BAP project\Papers\1-Journal paper _ Under review\CG\Submitted Files\Revision\Figs\';

%------------------Input Matrix Generation-------------------------------
cd(Figs);
   
%-----------------Reading input files--------------------
    Fig6Data=readmatrix([Figs 'Fig. 6 Data for MATLAB.xlsx']);

    wposX=100; wposY = 100;
    Length = 1000;
    Width = 1000;
    fig=figure('DefaultAxesFontSize',14,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
    figname = 'Fig6';
    hold on
     
    subplot(2,2,1)
    
    m=plot(Fig6Data(1:4,1),Fig6Data(1:4,2),'-ko','LineWidth',1.25,'MarkerSize',6);
%     m(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
        
    f=plot(Fig6Data(1:9,3),Fig6Data(1:9,4),'--ks','LineWidth',1.25,'MarkerSize',6);
%   f(1).MarkerFaceColor = [0.850 0.325 0.098];

    xlabel('Elevation [m]','FontSize',14);
    ylabel('Piezometric Head [m]','FontSize',14);
    xlim([1618 1694]);
    title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',18);
    
    legend('Monitoring','FDM','Location','northwest');

    subplot(2,2,2)

    m2=plot(Fig6Data(1:4,5),Fig6Data(1:4,6),'-ko','LineWidth',1.25,'MarkerSize',6);
%     m2(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
        
    f2=plot(Fig6Data(1:9,7),Fig6Data(1:9,8),'--ks','LineWidth',1.25,'MarkerSize',6);
%   f2(1).MarkerFaceColor = [0.850 0.325 0.098];

    xlabel('Elevation [m]','FontSize',14);
    ylabel('\delta_y [m]','FontSize',14);
    xlim([1618 1694]);
    title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',18);

    subplot(2,2,3)

    m3=plot(Fig6Data(1:2,9),Fig6Data(1:2,10),'-ko','LineWidth',1.25,'MarkerSize',6);
%     m3(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
        
    f3=plot(Fig6Data(1:10,11),Fig6Data(1:10,12),'--ks','LineWidth',1.25,'MarkerSize',6);
%   f3(1).MarkerFaceColor = [0.850 0.325 0.098];

    xlabel('Length [m]','FontSize',14);
    ylabel('(×10^6) \sigma_{xx} [Pa]','FontSize',14);
    xlim([124 149]);
    title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',18);

    hold on
    
    subplot(2,2,4)

    m4=plot(Fig6Data(1:6,13),Fig6Data(1:6,14),'-ko','LineWidth',1.25,'MarkerSize',6);
%     m4(1).MarkerFaceColor = [0.850 0.325 0.098];
    hold on
        
    f4=plot(Fig6Data(1:10,15),Fig6Data(1:10,16),'--ks','LineWidth',1.25,'MarkerSize',6);
%   f4(1).MarkerFaceColor = [0.850 0.325 0.098];

    xlabel('Length [m]','FontSize',14);
    ylabel('(×10^6) \sigma_{yy} [Pa]','FontSize',14);
    xlim([124 149]);
    title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',18);

    saveas(fig,[figname '.png']);
    close
