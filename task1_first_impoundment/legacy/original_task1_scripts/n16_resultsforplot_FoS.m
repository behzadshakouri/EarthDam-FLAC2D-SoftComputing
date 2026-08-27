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

nsample=[50 100 150 200 300 400 500];
ntrain(1,:)=ceil(nsample(1,:)*0.7);
ntest(1,:)=nsample(1,:)-ntrain(1,:);

for k=1:numel(nsample)


for a=1:4 
        

Comment=['FoS_' num2str(nsample) '_'];

    if a==1
    a1='ELM';
    ELMdata(:,k)=readmatrix([a1 '_FoS_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    elseif a==2
    a2='ELMABC';
    ELMABCdata(:,k)=readmatrix([a2 '_FoS_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    a3='ELMACOR';
    ELMACORdata(:,k)=readmatrix([a3 '_FoS_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
    elseif a==4
    a4='ELMIGWO';
    ELMIGWOdata(:,k)=readmatrix([a4 '_FoS_n' num2str(nsample(1,k)) '_Statistics' '.xlsx']); %#ok
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

    
    ELM.train.R2(:,k)=ELMdata(1,k);
    ELM.train.RMSE(:,k)=ELMdata(2,k);
    ELM.train.MAE(:,k)=ELMdata(3,k);
    ELM.train.a10(:,k)=ELMdata(4,k);
    ELM.test.R2(:,k)=ELMdata(5,k);
    ELM.test.RMSE(:,k)=ELMdata(6,k);
    ELM.test.MAE(:,k)=ELMdata(7,k);
    ELM.test.a10(:,k)=ELMdata(8,k);
    
    ELMABC.train.R2(:,k)=ELMABCdata(1,k);
    ELMABC.train.RMSE(:,k)=ELMABCdata(2,k);
    ELMABC.train.MAE(:,k)=ELMABCdata(3,k);
    ELMABC.train.a10(:,k)=ELMABCdata(4,k);
    ELMABC.test.R2(:,k)=ELMABCdata(5,k);
    ELMABC.test.RMSE(:,k)=ELMABCdata(6,k);
    ELMABC.test.MAE(:,k)=ELMABCdata(7,k);
    ELMABC.test.a10(:,k)=ELMABCdata(8,k);

    ELMACOR.train.R2(:,k)=ELMACORdata(1,k);
    ELMACOR.train.RMSE(:,k)=ELMACORdata(2,k);
    ELMACOR.train.MAE(:,k)=ELMACORdata(3,k);
    ELMACOR.train.a10(:,k)=ELMACORdata(4,k);
    ELMACOR.test.R2(:,k)=ELMACORdata(5,k);
    ELMACOR.test.RMSE(:,k)=ELMACORdata(6,k);
    ELMACOR.test.MAE(:,k)=ELMACORdata(7,k);
    ELMACOR.test.a10(:,k)=ELMACORdata(8,k);

    ELMIGWO.train.R2(:,k)=ELMIGWOdata(1,k);
    ELMIGWO.train.RMSE(:,k)=ELMIGWOdata(2,k);
    ELMIGWO.train.MAE(:,k)=ELMIGWOdata(3,k);
    ELMIGWO.train.a10(:,k)=ELMIGWOdata(4,k);
    ELMIGWO.test.R2(:,k)=ELMIGWOdata(5,k);
    ELMIGWO.test.RMSE(:,k)=ELMIGWOdata(6,k);
    ELMIGWO.test.MAE(:,k)=ELMIGWOdata(7,k);
    ELMIGWO.test.a10(:,k)=ELMIGWOdata(8,k);
    
end

close all

save FoS_results.mat