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
load FoS_results.mat
FoS='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\FoS (paper-revision-final)\';

nsample=[50 100 150 200 300 400 500];

cd(Figs)
          
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
%-----------------------------------------Train data Fig.-----------------------------        

        FoStrain=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        TitleFoStrain='Train data performance metrics changes for FoS';
        
%         figname = 'Fig16';
        hold on

        subplot(1,4,1)
        
        l=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        

        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = 'Train data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
%         close
 
        subplot(1,4,2)
        
        l=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[]; 
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = 'Train data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        ylim([0.9 1.1]);
        title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
%         close
 
        subplot(1,4,3)
        
        l=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[]; 
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = 'Train data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
%         close

        subplot(1,4,4)
        
        l=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        

        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = 'Train data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(FoStrain,[TitleFoStrain '.png']);
        close
        
        
%-----------------------------------------Test data Fig.-----------------------------        
        FoStest=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        TitleFoStest='Test data performance metrics changes for FoS';
        
        figname = 'Fig16';
        hold on

        subplot(1,4,1)
        
        l=5;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        

        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = 'Train data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(a)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
%         close
 
        subplot(1,4,2)
        
        l=8;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[]; 
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = 'Test data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        ylim([0.9 1.1]);
        title('\bf(b)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
%         close
 
        subplot(1,4,3)
        
        l=6;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[]; 
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = 'Test data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(c)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
%         close

        subplot(1,4,4)
        
        l=7;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        

        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = 'Test data R^2 ratio for FoS';
        xlabel('ntrain','FontSize',18);
        ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf(d)','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(FoStest,[TitleFoStest '.png']);
        close