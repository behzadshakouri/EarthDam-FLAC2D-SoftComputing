clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs\';
FoS='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\FoS\';


%------------------Input Matrix Generation-------------------------------

cd(FoS);
load FoS_results.mat

nsample=[50 100 150 200 300 400 500];
    
       
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hR2train=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleR2train = 'Train data R^2 changes for FoS';
        xlabel('ntrain');
        ylabel('R^2 ratio');
        title(hTitleR2train);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hRMSEtrain=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleRMSEtrain = 'Train data RMSE changes for FoS';
        xlabel('ntrain');
        ylabel('RMSE ratio');
        title(hTitleRMSEtrain);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hMAEtrain=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleMAEtrain = 'Train data MAE changes for FoS';
        xlabel('ntrain');
        ylabel('MAE ratio');
        title(hTitleMAEtrain);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        ha10train=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitlea10train = 'Train data a10-index changes for FoS';
        xlabel('ntrain');
        ylabel('a10-index ratio');
        title(hTitlea10train);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hR2test=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleR2test = 'Test data R^2 changes for FoS';
        xlabel('ntrain');
        ylabel('R^2 ratio');
        title(hTitleR2test);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hRMSEtest=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleRMSEtest = 'Test data RMSE changes for FoS';
        xlabel('ntrain');
        ylabel('RMSE ratio');
        title(hTitleRMSEtest);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        hMAEtest=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitleMAEtest = 'Test data MAE changes for FoS';
        xlabel('ntrain');
        ylabel('MAE ratio');
        title(hTitleMAEtest);
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
        y1=[y1 ELMABCdata(l,k)/ELMdata(l,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMACORdata(l,k)/ELMdata(l,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMIGWOdata(l,k)/ELMdata(l,k)]; %#ok
        k=k+1;
        end
        
        ha10test=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*');
        hTitlea10test = 'Test data a10-index changes for FoS';
        xlabel('ntrain');
        ylabel('a10-index ratio');
        title(hTitlea10test);
        legend('ELM-ABC/ELM','ELM-ACOR/ELM','ELM-IGWO/ELM');
        saveas(ha10test,[hTitlea10test '.png']); 
        close
        
        end
    end

close all

save FoS_results5.mat
