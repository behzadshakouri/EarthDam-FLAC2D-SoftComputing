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
load results.mat
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';

nsample=[50 100 150 200 300 400 500];
%output_r=[1 2 3 4 5 6 7 8 9 10]; 
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];
Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

cd(Figs);

for i=3:3 %QoI3 %1:numel(node_row) %QoIs
    
    for l=1:8 %1:8  %circumstances
%     for j=1:4 %responses
    if l==1
        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        hR2train=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleR2train=['Train data R^2 ratio for QoI' num2str(i)];
%         figname = 'Fig9';
        hold on
%         hR2train=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = ['Train data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = ['Train data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = ['Train data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);\
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2train = ['Train data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2train,[hTitleR2train '.png']);

        saveas(hR2train,[hTitleR2train '.png']);
        close
        
        elseif l==2

        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        hRMSEtrain=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleRMSEtrain=['Train data RMSE ratio for QoI' num2str(i)];
%         figname = 'Fig11';
        hold on
%         hRMSEtrain=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtrain = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtrain = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtrain = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtrain = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);

        saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
        close

%         
        elseif l==3

        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        hMAEtrain=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleMAEtrain=['Train data MAE ratio for QoI' num2str(i)];
%         figname = 'Fig12';
        hold on
%         hMAEtrain=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtrain = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtrain,[hTitleMAEtrain '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtrain = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtrain,[hTitleMAEtrain '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtrain = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);\
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtrain,[hTitleMAEtrain '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtrain = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtrain,[hTitleMAEtrain '.png']);

        saveas(hMAEtrain,[hTitleMAEtrain '.png']);
        close

         
        elseif l==4
            
        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        ha10train=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitlea10train=['Train data a10-index ratio for QoI' num2str(i)];
%         figname = 'Fig10';
        hold on
%         ha10train=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10train = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10train,[hTitlea10train '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10train = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10train,[hTitlea10train '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10train = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);\
        xlim([25 360]);
        ylim([0.9 1.1]); %ylimit change
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10train,[hTitlea10train '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10train = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10train,[hTitlea10train '.png']);

        saveas(ha10train,[hTitlea10train '.png']);
        close
        
        
        elseif l==5
            
        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
%         figname = 'Fig9';
        hR2test=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleR2test=['Test data R^2 ratio for QoI' num2str(i)];
        figname = 'Fig9';
        hold on
%         hR2test=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = ['test data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = ['Test data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = ['Test data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleR2test = ['Test data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('R^2 ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hR2test,[hTitleR2test '.png']);
        saveas(hR2test,[hTitleR2test '.png']);
        close
               

%         
        elseif l==6

        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        hRMSEtest=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleRMSEtest=['Test data RMSE ratio for QoI' num2str(i)];
        figname = 'Fig11';
        hold on
%         hRMSEtest=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtest = ['Test data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtest,[hTitleRMSEtest '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtest = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtest,[hTitleRMSEtest '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtest = ['Test data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtest,[hTitleRMSEtest '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleRMSEtest = ['Test data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('RMSE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hRMSEtest,[hTitleRMSEtest '.png']);

        saveas(hRMSEtest,[hTitleRMSEtest '.png']);
        close

%         
        elseif l==7

j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        hMAEtest=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitleMAEtest=['Test data MAE ratio for QoI' num2str(i)];
        figname = 'Fig12';
        hold on
%         hMAEtest=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtest = ['Test data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtest,[hTitleMAEtest '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtest = ['Test data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtest,[hTitleMAEtest '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtest = ['Test data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);\
        xlim([25 360]);
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtest,[hTitleMAEtest '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitleMAEtest = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('MAE ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(hMAEtest,[hTitleMAEtest '.png']);

        saveas(hMAEtest,[hTitleMAEtest '.png']);
        close


        elseif l==8
        
        j=1;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];      
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        wposX=100; wposY = 100;
        Length = 1000;
        Width = 2400;
        ha10test=figure('DefaultAxesFontSize',18,'Renderer', 'painters', 'Position', [wposX wposY Width Length]);
        hTitlea10test=['Test data a10-index ratio for QoI' num2str(i)];
        figname = 'Fig10';
        hold on
%         ha10test=figure('DefaultAxesFontSize',18);
        
        subplot(1,4,1)
        
        p1=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p1(1), 'Color', [1 0 0]);
        set(p1(2), 'Color', [0.466 0.674 0.188]);
        set(p1(3), 'Color', [0 0.447 0.741]);
        p1(1).MarkerFaceColor = [0.850 0.325 0.098];
        p1(2).MarkerFaceColor = [0.6 0.8 0.2];
        p1(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10test = ['Test data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
        ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(a) \delta_x}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10test,[hTitlea10test '.png']);
        hold on

        j=2;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,2)
        
        p2=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p2(1), 'Color', [1 0 0]);
        set(p2(2), 'Color', [0.466 0.674 0.188]);
        set(p2(3), 'Color', [0 0.447 0.741]);
        p2(1).MarkerFaceColor = [0.850 0.325 0.098];
        p2(2).MarkerFaceColor = [0.6 0.8 0.2];
        p2(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10test = ['Test data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(b) \delta_y}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10test,[hTitlea10test '.png']);
%         
        
        j=3;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        subplot(1,4,3)
        
        p3=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p3(1), 'Color', [1 0 0]);
        set(p3(2), 'Color', [0.466 0.674 0.188]);
        set(p3(3), 'Color', [0 0.447 0.741]);
        p3(1).MarkerFaceColor = [0.850 0.325 0.098];
        p3(2).MarkerFaceColor = [0.6 0.8 0.2];
        p3(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10test = ['Test data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);\
        xlim([25 360]);
        ylim([0.9 1.1]); %ylimit change
        title('\bf{(c) \sigma_{xx}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10test,[hTitlea10test '.png']);
% 

        j=4;
        k=1;
        x1=[];
        x2=[];
        x3=[];
        y1=[];
        y2=[];
        y3=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMABCdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(j,l,i,k)/ELMdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        
        subplot(1,4,4)
        
        p4=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p4(1), 'Color', [1 0 0]);
        set(p4(2), 'Color', [0.466 0.674 0.188]);
        set(p4(3), 'Color', [0 0.447 0.741]);
        p4(1).MarkerFaceColor = [0.850 0.325 0.098];
        p4(2).MarkerFaceColor = [0.6 0.8 0.2];
        p4(3).MarkerFaceColor = [0.494 0.184 0.556];
%         hTitlea10test = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',18);
%         ylabel('a10-index ratio','FontSize',18);
        xlim([25 360]);
        title('\bf{(d) \sigma_{yy}}','Units', 'normalized', 'Position', [0.5, 1.01, 1.01],'FontSize',18);
%         legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
%         saveas(ha10test,[hTitlea10test '.png']);

        saveas(ha10test,[hTitlea10test '.png']);
        close  
                 
    end
%     end
    end
end