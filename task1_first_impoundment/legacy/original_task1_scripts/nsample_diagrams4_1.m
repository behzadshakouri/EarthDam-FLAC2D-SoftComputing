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

ndata=500;
ntrainmax=0.7*ndata;


for j=1:4 %responses       
    for l=1:4 %performance metrics & train or test (train+4)
    for i=1:numel(node_row) %node number
        
        if l==1
        x1=[];
        x11=[];
        x2=[];
        x22=[];
        x3=[];
        x33=[];
        x4=[];
        x44=[];
        y1=[];
        y11=[];
        y2=[];
        y22=[];
        y3=[];
        y33=[];
        y4=[];
        y44=[];
        k=1;
        
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        x11=[x11 ntrainmax+ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        y11=[y11 ELMdata(j,l+4,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        x22=[x22 ntrainmax+ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        y22=[y22 ELMABCdata(j,l+4,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        x33=[x33 ntrainmax+ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        y33=[y33 ELMACORdata(j,l+4,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        x44=[x44 ntrainmax+ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        y44=[y44 ELMIGWOdata(j,l+4,i,k)]; %#ok
        k=k+1;
        end
        
        hR2=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+',x11,y11,'r--^',x22,y22,'g--.',x33,y33,'b--x',x44,y44,'m--v');
        hTitleR2 = ['R2 changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('n');
        ylabel('R2');
        title(hTitleR2);
        legend('ELM--train','ELM-ABC--train','ELM-ACOR--train','ELM-IGWO--train','ELM-test','ELM-ABC--test','ELM-ACOR--test','ELM-IGWO--test','Location','bestoutside');
        saveas(hR2,[hTitleR2 '.png']);
        close
        
        elseif l==2
        x1=[];
        x11=[];
        x2=[];
        x22=[];
        x3=[];
        x33=[];
        x4=[];
        x44=[];
        y1=[];
        y11=[];
        y2=[];
        y22=[];
        y3=[];
        y33=[];
        y4=[];
        y44=[];
        k=1;
        
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        x11=[x11 ntrainmax+ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        y11=[y11 ELMdata(j,l+4,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        x22=[x22 ntrainmax+ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        y22=[y22 ELMABCdata(j,l+4,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        x33=[x33 ntrainmax+ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        y33=[y33 ELMACORdata(j,l+4,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        x44=[x44 ntrainmax+ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        y44=[y44 ELMIGWOdata(j,l+4,i,k)]; %#ok
        k=k+1;
        end
        
        hRMSE=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+',x11,y11,'r--^',x22,y22,'g--.',x33,y33,'b--x',x44,y44,'m--v');
        hTitleRMSE = ['RMSE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('n');
        ylabel('RMSE');
        title(hTitleRMSE);
        legend('ELM--train','ELM-ABC--train','ELM-ACOR--train','ELM-IGWO--train','ELM-test','ELM-ABC--test','ELM-ACOR--test','ELM-IGWO--test','Location','bestoutside');
        saveas(hRMSE,[hTitleRMSE '.png']);
        close
        
        elseif l==3
        x1=[];
        x11=[];
        x2=[];
        x22=[];
        x3=[];
        x33=[];
        x4=[];
        x44=[];
        y1=[];
        y11=[];
        y2=[];
        y22=[];
        y3=[];
        y33=[];
        y4=[];
        y44=[];
        k=1;
        
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        x11=[x11 ntrainmax+ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        y11=[y11 ELMdata(j,l+4,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        x22=[x22 ntrainmax+ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        y22=[y22 ELMABCdata(j,l+4,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        x33=[x33 ntrainmax+ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        y33=[y33 ELMACORdata(j,l+4,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        x44=[x44 ntrainmax+ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        y44=[y44 ELMIGWOdata(j,l+4,i,k)]; %#ok
        k=k+1;
        end
        
        hMAE=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+',x11,y11,'r--^',x22,y22,'g--.',x33,y33,'b--x',x44,y44,'m--v');
        hTitleMAE = ['MAE changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('n');
        ylabel('MAE');
        title(hTitleMAE);
        legend('ELM--train','ELM-ABC--train','ELM-ACOR--train','ELM-IGWO--train','ELM-test','ELM-ABC--test','ELM-ACOR--test','ELM-IGWO--test','Location','bestoutside');
        saveas(hMAE,[hTitleMAE '.png']);
        close
        
        elseif l==4
        x1=[];
        x11=[];
        x2=[];
        x22=[];
        x3=[];
        x33=[];
        x4=[];
        x44=[];
        y1=[];
        y11=[];
        y2=[];
        y22=[];
        y3=[];
        y33=[];
        y4=[];
        y44=[];
        k=1;
        
        while k<=max(numel(nsample))
        x1=[x1 ntrain(1,k)]; %#ok
        x11=[x11 ntrainmax+ntest(1,k)]; %#ok
        y1=[y1 ELMdata(j,l,i,k)]; %#ok
        y11=[y11 ELMdata(j,l+4,i,k)]; %#ok
        x2=[x2 ntrain(1,k)]; %#ok
        x22=[x22 ntrainmax+ntest(1,k)]; %#ok
        y2=[y2 ELMABCdata(j,l,i,k)]; %#ok
        y22=[y22 ELMABCdata(j,l+4,i,k)]; %#ok
        x3=[x3 ntrain(1,k)]; %#ok
        x33=[x33 ntrainmax+ntest(1,k)]; %#ok
        y3=[y3 ELMACORdata(j,l,i,k)]; %#ok
        y33=[y33 ELMACORdata(j,l+4,i,k)]; %#ok
        x4=[x4 ntrain(1,k)]; %#ok
        x44=[x44 ntrainmax+ntest(1,k)]; %#ok
        y4=[y4 ELMIGWOdata(j,l,i,k)]; %#ok
        y44=[y44 ELMIGWOdata(j,l+4,i,k)]; %#ok
        k=k+1;
        end
        
        ha10=figure;
        plot(x1,y1,'r-s',x2,y2,'g-o',x3,y3,'b-*',x4,y4,'m-+',x11,y11,'r--^',x22,y22,'g--.',x33,y33,'b--x',x44,y44,'m--v');
        hTitlea10 = ['a10-index changes for ' Res{1,j} ' & QoI' num2str(i)];
        xlabel('n');
        ylabel('a10-index');
        title(hTitlea10);
        legend('ELM--train','ELM-ABC--train','ELM-ACOR--train','ELM-IGWO--train','ELM-test','ELM-ABC--test','ELM-ACOR--test','ELM-IGWO--test','Location','bestoutside');
        saveas(ha10,[hTitlea10 '.png']);
        close
        
        end
    end
    end
end

close all

save results4.mat
