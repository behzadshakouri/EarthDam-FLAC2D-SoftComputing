clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\';


%------------------Input Matrix Generation-------------------------------

cd(QOIs);

%output_r=[1 2 3 4 5 6 7 8 9 10]; 
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for a=1:4
    
for j=1:4

for i=1:numel(node_row)
    
QOIn=[QOIs 'QOI_' num2str(i)];
cd(QOIn);
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];

if a==1
    a1='ELM';
elseif a==2
    a1='ELMABC';
elseif a==3
    a1='ELMACOR';
elseif a==4
    a1='ELMIGWO';
end

data=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_Statistics' '.xlsx']);

train.R2(j,i)=data(1,1);
train.RMSE(j,i)=data(1,2);
train.MAE(j,i)=data(1,3);
train.a10(j,i)=data(1,4);
test.R2(j,i)=data(1,5);
test.RMSE(j,i)=data(1,6);
test.MAE(j,i)=data(1,7);
test.a10(j,i)=data(1,8);

end
end


for j=1:4

%------------------Standardization in [0, 1]------------------------
%[train.R2n(j,:) trainR2is]=mapminmax(train.R2(j,:),0,1);
%[train.RMSEn(j,:) trainRMSEis]=mapminmax(train.RMSE(j,:),0,1);
%[train.MAEn(j,:) trainMAEis]=mapminmax(train.MAE(j,:),0,1);
%[train.a10n(j,:) traina10is]=mapminmax(train.a10(j,:),0,1);
%[test.R2n(j,:) testR2is]=mapminmax(test.R2(j,:),0,1);
%[test.RMSEn(j,:) testRMSEis]=mapminmax(test.RMSE(j,:),0,1);
%[test.MAEn(j,:) testMAEis]=mapminmax(test.MAE(j,:),0,1);
%[test.a10n(j,:) testa10is]=mapminmax(test.a10(j,:),0,1);

%------------------Heat map production-------------------------------

cd(QOIs);
%traindata=[train.a10n(j,:);train.MAEn(j,:);train.RMSEn(j,:);train.R2n(j,:)];
data=[test.MAE(j,:);train.MAE(j,:);test.RMSE(j,:);train.RMSE(j,:);test.a10(j,:);train.a10(j,:);test.R2(j,:);train.R2(j,:)];
xvalues = {'Q1','Q2','Q3','Q4','Q5','Q6','Q7','Q8','Q9'};
yvalues = {'MAE-test','MAE-train','RMSE-test','RMSE-train','a10-index-test','a10-index-train','R2-test','R2-train'};
wposX=100; wposY = 100;
heatmapLength = 1000;
heatmapWidth = 1000;
figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h=heatmap(xvalues,yvalues,data);
h.Title = [a1 ' Results for ' Res{1,j}];
h.XLabel = 'QoIs';
h.YLabel = 'Performance metrics';
saveas(h,[h.Title '.png']);
close

end

end
