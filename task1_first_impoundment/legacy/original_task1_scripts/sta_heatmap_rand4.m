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

cd(QOIs);

for nsample=[50 100 200 300 400 500]
    
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
QOInsample=[QOIn '\n' num2str(nsample) '\'];
cd(QOInsample);
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];

if a==1
    a1='ELM';
    ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Statistics' '.xlsx']);
    ELM.train.R2(j,i)=ELMdata(1,1);
    ELM.train.RMSE(j,i)=ELMdata(1,2);
    ELM.train.MAE(j,i)=ELMdata(1,3);
    ELM.train.a10(j,i)=ELMdata(1,4);
    ELM.test.R2(j,i)=ELMdata(1,5);
    ELM.test.RMSE(j,i)=ELMdata(1,6);
    ELM.test.MAE(j,i)=ELMdata(1,7);
    ELM.test.a10(j,i)=ELMdata(1,8);
elseif a==2
    a2='ELMABC';
    ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Statistics' '.xlsx']);
    ELMABC.train.R2(j,i)=ELMABCdata(1,1);
    ELMABC.train.RMSE(j,i)=ELMABCdata(1,2);
    ELMABC.train.MAE(j,i)=ELMABCdata(1,3);
    ELMABC.train.a10(j,i)=ELMABCdata(1,4);
    ELMABC.test.R2(j,i)=ELMABCdata(1,5);
    ELMABC.test.RMSE(j,i)=ELMABCdata(1,6);
    ELMABC.test.MAE(j,i)=ELMABCdata(1,7);
    ELMABC.test.a10(j,i)=ELMABCdata(1,8);
elseif a==3
    a3='ELMACOR';
    ELMACORdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Statistics' '.xlsx']);
    ELMACOR.train.R2(j,i)=ELMACORdata(1,1);
    ELMACOR.train.RMSE(j,i)=ELMACORdata(1,2);
    ELMACOR.train.MAE(j,i)=ELMACORdata(1,3);
    ELMACOR.train.a10(j,i)=ELMACORdata(1,4);
    ELMACOR.test.R2(j,i)=ELMACORdata(1,5);
    ELMACOR.test.RMSE(j,i)=ELMACORdata(1,6);
    ELMACOR.test.MAE(j,i)=ELMACORdata(1,7);
    ELMACOR.test.a10(j,i)=ELMACORdata(1,8);
elseif a==4
    a4='ELMIGWO';
    ELMIGWOdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Statistics' '.xlsx']);
    ELMIGWO.train.R2(j,i)=ELMIGWOdata(1,1);
    ELMIGWO.train.RMSE(j,i)=ELMIGWOdata(1,2);
    ELMIGWO.train.MAE(j,i)=ELMIGWOdata(1,3);
    ELMIGWO.train.a10(j,i)=ELMIGWOdata(1,4);
    ELMIGWO.test.R2(j,i)=ELMIGWOdata(1,5);
    ELMIGWO.test.RMSE(j,i)=ELMIGWOdata(1,6);
    ELMIGWO.test.MAE(j,i)=ELMIGWOdata(1,7);
    ELMIGWO.test.a10(j,i)=ELMIGWOdata(1,8);
end

end
end
end
end

for nsample=[50 100 200 300 400 500]
for j=1:4 %responses

%------------------Heat map production-------------------------------

cd(QOIs);
f='Results';
folder=strcat(f);
if ~exist(folder, 'dir')
mkdir(Results,folder);
end

f='n';
folder=strcat(f,num2str(nsample));
if ~exist(folder, 'dir')
mkdir(Results,folder);
end

cd([Results 'n' num2str(nsample) '\']);

%traindata=[train.a10n(j,:);train.MAEn(j,:);train.RMSEn(j,:);train.R2n(j,:)];
R2=[ELMIGWO.test.R2(j,:);ELMIGWO.train.R2(j,:);ELMACOR.test.R2(j,:);ELMACOR.train.R2(j,:);ELMABC.test.R2(j,:);ELMABC.train.R2(j,:);ELM.test.R2(j,:);ELM.train.R2(j,:)];
a10=[ELMIGWO.test.a10(j,:);ELMIGWO.train.a10(j,:);ELMACOR.test.a10(j,:);ELMACOR.train.a10(j,:);ELMABC.test.a10(j,:);ELMABC.train.a10(j,:);ELM.test.a10(j,:);ELM.train.a10(j,:)];
RMSE=[ELMIGWO.test.RMSE(j,:);ELMIGWO.train.RMSE(j,:);ELMACOR.test.RMSE(j,:);ELMACOR.train.RMSE(j,:);ELMABC.test.RMSE(j,:);ELMABC.train.RMSE(j,:);ELM.test.RMSE(j,:);ELM.train.RMSE(j,:)];
MAE=[ELMIGWO.test.MAE(j,:);ELMIGWO.train.MAE(j,:);ELMACOR.test.MAE(j,:);ELMACOR.train.MAE(j,:);ELMABC.test.MAE(j,:);ELMABC.train.MAE(j,:);ELM.test.MAE(j,:);ELM.train.MAE(j,:)];

xvalues = {'Q1','Q2','Q3','Q4','Q5','Q6','Q7','Q8','Q9'};
yvalues = {'ELM-IGWO--test','ELM-IGWO--train','ELM-ACOR--test','ELM-ACOR--train','ELM-ABC--test','ELM-ABC--train','ELM--test','ELM--train'};
wposX=100; wposY = 100;
heatmapLength = 1000;
heatmapWidth = 1000;

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h1=heatmap(xvalues,yvalues,R2);
%h1.ColorScaling = 'scaledrows';
h1.Title = ['R2 results for ' Res{1,j} ' & nsample' num2str(nsample)];
h1.XLabel = 'QoIs';
h1.YLabel = 'Performance metrics';
h1.CellLabelFormat = '%.2f';
saveas(h1,[h1.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h2=heatmap(xvalues,yvalues,a10);
%h2.ColorScaling = 'scaledrows';
h2.Title = ['a10-index results for ' Res{1,j} ' & nsample' num2str(nsample)];
h2.XLabel = 'QoIs';
h2.YLabel = 'Performance metrics';
h2.CellLabelFormat = '%.2f';
saveas(h2,[h2.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h3=heatmap(xvalues,yvalues,RMSE);
%h3.ColorScaling = 'scaledrows';
h3.Title = ['RMSE results for ' Res{1,j} ' & nsample' num2str(nsample)];
h3.XLabel = 'QoIs';
h3.YLabel = 'Performance metrics';
if j==1
    h3.CellLabelFormat = '%.2f';
elseif j==2
    h3.CellLabelFormat = '%.2f';
else
    h3.CellLabelFormat = '%.0f';
end
saveas(h3,[h3.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h4=heatmap(xvalues,yvalues,MAE);
%h4.ColorScaling = 'scaledrows';
h4.Title = ['MAE results for ' Res{1,j} ' & nsample' num2str(nsample)];
h4.XLabel = 'QoIs';
h4.YLabel = 'Performance metrics';
if j==1
    h4.CellLabelFormat = '%.2f';
elseif j==2
    h4.CellLabelFormat = '%.2f';
else
    h4.CellLabelFormat = '%.0f';
end
saveas(h4,[h4.Title '.png']);
close

end
end

save results3.mat