clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision)\';
Results='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision)\Results\';


%------------------Input Matrix Generation-------------------------------

cd(QOIs);

nsample=[50 100 150 200 300 400 500];
ntrain(1,:)=ceil(nsample(1,:)*0.7);
ntest(1,:)=nsample(1,:)-ntrain(1,:);

for k=1:numel(nsample)

    
%output_r=[1 2 3 4 5 6 7 8 9 10]; 
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for a=1:4   
for j=1:4
for i=1:numel(node_row)
    
QOIn=[QOIs 'QOI_' num2str(i)];
QOInsample=[QOIn '\n' num2str(nsample(1,k)) '\'];
cd(QOInsample);
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];

    if a==1
    a1='ELM';
    ELMdata(j,:,i,k)=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    elseif a==2
    a2='ELMABC';
    ELMABCdata(j,:,i,k)=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    a3='ELMACOR';
    ELMACORdata(j,:,i,k)=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    elseif a==4
    a4='ELMIGWO';
    ELMIGWOdata(j,:,i,k)=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    end
    
end
end
end

% for j=1:4

%------------------Standardization in [0, 1]------------------------
%[train.R2n(j,:) trainR2is]=mapminmax(train.R2(j,:),0,1);
%[train.RMSEn(j,:) trainRMSEis]=mapminmax(train.RMSE(j,:),0,1);
%[train.MAEn(j,:) trainMAEis]=mapminmax(train.MAE(j,:),0,1);
%[train.a10n(j,:) traina10is]=mapminmax(train.a10(j,:),0,1);
%[test.R2n(j,:) testR2is]=mapminmax(test.R2(j,:),0,1);
%[test.RMSEn(j,:) testRMSEis]=mapminmax(test.RMSE(j,:),0,1);
%[test.MAEn(j,:) testMAEis]=mapminmax(test.MAE(j,:),0,1);
%[test.a10n(j,:) testa10is]=mapminmax(test.a10(j,:),0,1);

%------------------nsample diagrams production-------------------------------


for i=1:numel(node_row)
    
    ELM.train.R2(:,i,k)=ELMdata(:,1,i,k);
    ELM.train.RMSE(:,i,k)=ELMdata(:,2,i,k);
    ELM.train.MAE(:,i,k)=ELMdata(:,3,i,k);
    ELM.train.a10(:,i,k)=ELMdata(:,4,i,k);
    ELM.test.R2(:,i,k)=ELMdata(:,5,i,k);
    ELM.test.RMSE(:,i,k)=ELMdata(:,6,i,k);
    ELM.test.MAE(:,i,k)=ELMdata(:,7,i,k);
    ELM.test.a10(:,i,k)=ELMdata(:,8,i,k);
    
    ELMABC.train.R2(:,i,k)=ELMABCdata(:,1,i,k);
    ELMABC.train.RMSE(:,i,k)=ELMABCdata(:,2,i,k);
    ELMABC.train.MAE(:,i,k)=ELMABCdata(:,3,i,k);
    ELMABC.train.a10(:,i,k)=ELMABCdata(:,4,i,k);
    ELMABC.test.R2(:,i,k)=ELMABCdata(:,5,i,k);
    ELMABC.test.RMSE(:,i,k)=ELMABCdata(:,6,i,k);
    ELMABC.test.MAE(:,i,k)=ELMABCdata(:,7,i,k);
    ELMABC.test.a10(:,i,k)=ELMABCdata(:,8,i,k);

    ELMACOR.train.R2(:,i,k)=ELMACORdata(:,1,i,k);
    ELMACOR.train.RMSE(:,i,k)=ELMACORdata(:,2,i,k);
    ELMACOR.train.MAE(:,i,k)=ELMACORdata(:,3,i,k);
    ELMACOR.train.a10(:,i,k)=ELMACORdata(:,4,i,k);
    ELMACOR.test.R2(:,i,k)=ELMACORdata(:,5,i,k);
    ELMACOR.test.RMSE(:,i,k)=ELMACORdata(:,6,i,k);
    ELMACOR.test.MAE(:,i,k)=ELMACORdata(:,7,i,k);
    ELMACOR.test.a10(:,i,k)=ELMACORdata(:,8,i,k);

    ELMIGWO.train.R2(:,i,k)=ELMIGWOdata(:,1,i,k);
    ELMIGWO.train.RMSE(:,i,k)=ELMIGWOdata(:,2,i,k);
    ELMIGWO.train.MAE(:,i,k)=ELMIGWOdata(:,3,i,k);
    ELMIGWO.train.a10(:,i,k)=ELMIGWOdata(:,4,i,k);
    ELMIGWO.test.R2(:,i,k)=ELMIGWOdata(:,5,i,k);
    ELMIGWO.test.RMSE(:,i,k)=ELMIGWOdata(:,6,i,k);
    ELMIGWO.test.MAE(:,i,k)=ELMIGWOdata(:,7,i,k);
    ELMIGWO.test.a10(:,i,k)=ELMIGWOdata(:,8,i,k);
    
end    
end

close all

folder='Results';
cd(QOIs);
mkdir(QOIs,folder);
cd(Results)

save results.mat