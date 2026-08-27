clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\';
Results='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\Results\';


%------------------Input Matrix Generation-------------------------------

cd(Results);
load results.mat

for i=1:numel(node_row)

for j=1:4        
    for l=1:8
        
        if l==1
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];       
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hR2train=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleR2train = ['train data R2 changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntrain');
        ylabel('R2');
        title(hTitleR2train);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hR2train,[hTitleR2train '.png']);
        close
        
        elseif l==2
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        k=1;
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hRMSEtrain=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleRMSEtrain = ['train data RMSE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntrain');
        ylabel('RMSE');
        title(hTitleRMSEtrain);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hRMSEtrain,[hTitleRMSEtrain '.png']);
        close
        
        elseif l==3
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hMAEtrain=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleMAEtrain = ['train data MAE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntrain');
        ylabel('MAE');
        title(hTitleMAEtrain);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hMAEtrain,[hTitleMAEtrain '.png']);
        close
        
        elseif l==4
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        ha10train=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitlea10train = ['train data a10 changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntrain');
        ylabel('a10');
        title(hTitlea10train);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(ha10train,[hTitlea10train '.png']);
        close
        
        elseif l==5
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hR2test=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleR2test = ['test data R2 changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntest');
        ylabel('R2');
        title(hTitleR2test);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hR2test,[hTitleR2test '.png']); 
        close
        
        elseif l==6
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hRMSEtest=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleRMSEtest = ['test data RMSE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntest');
        ylabel('RMSE');
        title(hTitleRMSEtest);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hRMSEtest,[hTitleRMSEtest '.png']);
        close
        
        elseif l==7
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        hMAEtest=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitleMAEtest = ['test data MAE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntest');
        ylabel('MAE');
        title(hTitleMAEtest);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(hMAEtest,[hTitleMAEtest '.png']);
        close
        
        elseif l==8
        k=1;
        x1=[];
        x2=[];
        x3=[];
        x4=[];
        y1=[];
        y2=[];
        y3=[];
        y4=[];  
        while k<=max(numel(nsample))
        x1=[x1 ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        x2=[x2 ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        x3=[x3 ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        x4=[x4 ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        k=k+1;
        end
        
        ha10test=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+');
        hTitlea10test = ['test data a10 changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('ntest');
        ylabel('a10');
        title(hTitlea10test);
        legend('ELM','ELMABC','ELMACOR','ELMIGWO');
        saveas(ha10test,[hTitlea10test '.png']); 
        close
        
        end
    end
end
end

close all

save results2.mat
