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
load results.mat
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision-final)\Results\';

nsample=[50 100 150 200 300 400 500];
    
for i=1:numel(node_row)

for j=1:4        
    for l=1:8
        
        if l==1
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
        
        hR2train=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleR2train = ['Train data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('R^2 ratio','FontSize',14);
        title(hTitleR2train,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hR2train,[hTitleR2train '.png']);
        close
        
        elseif l==2
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
        
        hRMSEtrain=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleRMSEtrain = ['Train data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('RMSE ratio', 'FontSize',14);
        title(hTitleRMSEtrain,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
        close
        
        elseif l==3
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
        
        hMAEtrain=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleMAEtrain = ['Train data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('MAE ratio','FontSize',14);
        title(hTitleMAEtrain,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hMAEtrain,[hTitleMAEtrain '.png']);
        close
        
        elseif l==4
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
        
        ha10train=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitlea10train = ['Train data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('a10-index ratio','FontSize',14);
        title(hTitlea10train,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(ha10train,[hTitlea10train '.png']);
        close
        
        elseif l==5
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
        
        hR2test=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleR2test = ['Test data R^2 ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('R^2 ratio','FontSize',14);
        title(hTitleR2test,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hR2test,[hTitleR2test '.png']); 
        close
        
        elseif l==6
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
        
        hRMSEtest=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleRMSEtest = ['Test data RMSE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('RMSE ratio','FontSize',14);
        title(hTitleRMSEtest,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hRMSEtest,[hTitleRMSEtest '.png']);
        close
        
        elseif l==7
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
        
        hMAEtest=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitleMAEtest = ['Test data MAE ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('MAE ratio','FontSize',14);
        title(hTitleMAEtest,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(hMAEtest,[hTitleMAEtest '.png']);
        close
        
        elseif l==8
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
        
        ha10test=figure('DefaultAxesFontSize',14);
        p=plot(x1,y1,'-s',x2,y2,'-o',x3,y3,'-*','LineWidth',1.25,'MarkerSize',6);
        set(p(1), 'Color', [1 0 0]);
        set(p(2), 'Color', [0.466 0.674 0.188]);
        set(p(3), 'Color', [0 0.447 0.741]);
        p(1).MarkerFaceColor = [0.850 0.325 0.098];
        p(2).MarkerFaceColor = [0.6 0.8 0.2];
        p(3).MarkerFaceColor = [0.494 0.184 0.556];
        hTitlea10test = ['Test data a10-index ratio of ' Res{1,j} ' for QoI' num2str(i)];
        xlabel('ntrain','FontSize',14);
        ylabel('a10-index ratio','FontSize',14);
        title(hTitlea10test,'Units', 'normalized', 'Position', [0.5, 1.02, 1.02],'FontSize',12);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(ha10test,[hTitlea10test '.png']); 
        close
        
        end
    end
end
end

close all

save results5.mat
