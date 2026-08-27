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

cd(QOIs);

for nsample=[50 100 150 200 300 400 500]
    
%output_r=[1 2 3 4 5 6 7 8 9 10]; 
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for a=1:4 %methods
    
for j=1:4 %responses

for i=1:numel(node_row) %node numbers
    
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

for nsample=[50 100 150 200 300 400 500]

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
R2disp=[ELMIGWO.test.R2(2,:);ELMIGWO.train.R2(2,:);ELMIGWO.test.R2(1,:);ELMIGWO.train.R2(1,:);ELMACOR.test.R2(2,:); ...
    ELMACOR.train.R2(2,:);ELMACOR.test.R2(1,:);ELMACOR.train.R2(1,:);ELMABC.test.R2(2,:);ELMABC.train.R2(2,:); ...
    ELMABC.test.R2(1,:);ELMABC.train.R2(1,:);ELM.test.R2(2,:);ELM.train.R2(2,:);ELM.test.R2(1,:);ELM.train.R2(1,:)];
a10disp=[ELMIGWO.test.a10(2,:);ELMIGWO.train.a10(2,:);ELMIGWO.test.a10(1,:);ELMIGWO.train.a10(1,:);ELMACOR.test.a10(2,:); ...
    ELMACOR.train.a10(2,:);ELMACOR.test.a10(1,:);ELMACOR.train.a10(1,:);ELMABC.test.a10(2,:);ELMABC.train.a10(2,:); ...
    ELMABC.test.a10(1,:);ELMABC.train.a10(1,:);ELM.test.a10(2,:);ELM.train.a10(2,:);ELM.test.a10(1,:);ELM.train.a10(1,:)];
RMSEdisp=[ELMIGWO.test.RMSE(2,:);ELMIGWO.train.RMSE(2,:);ELMIGWO.test.RMSE(1,:);ELMIGWO.train.RMSE(1,:);ELMACOR.test.RMSE(2,:); ... 
    ELMACOR.train.RMSE(2,:);ELMACOR.test.RMSE(1,:);ELMACOR.train.RMSE(1,:);ELMABC.test.RMSE(2,:);ELMABC.train.RMSE(2,:); ...
    ELMABC.test.RMSE(1,:);ELMABC.train.RMSE(1,:);ELM.test.RMSE(2,:);ELM.train.RMSE(2,:);ELM.test.RMSE(1,:);ELM.train.RMSE(1,:)];
MAEdisp=[ELMIGWO.test.MAE(2,:);ELMIGWO.train.MAE(2,:);ELMIGWO.test.MAE(1,:);ELMIGWO.train.MAE(1,:);ELMACOR.test.MAE(2,:); ... 
    ELMACOR.train.MAE(2,:);ELMACOR.test.MAE(1,:);ELMACOR.train.MAE(1,:);ELMABC.test.MAE(2,:);ELMABC.train.MAE(2,:); ...
    ELMABC.test.MAE(1,:);ELMABC.train.MAE(1,:);ELM.test.MAE(2,:);ELM.train.MAE(2,:);ELM.test.MAE(1,:);ELM.train.MAE(1,:)];

R2stress=[ELMIGWO.test.R2(4,:);ELMIGWO.train.R2(4,:);ELMIGWO.test.R2(3,:);ELMIGWO.train.R2(3,:);ELMACOR.test.R2(4,:); ...
    ELMACOR.train.R2(4,:);ELMACOR.test.R2(3,:);ELMACOR.train.R2(3,:);ELMABC.test.R2(4,:);ELMABC.train.R2(4,:); ...
    ELMABC.test.R2(3,:);ELMABC.train.R2(3,:);ELM.test.R2(4,:);ELM.train.R2(4,:);ELM.test.R2(3,:);ELM.train.R2(3,:)];
a10stress=[ELMIGWO.test.a10(4,:);ELMIGWO.train.a10(4,:);ELMIGWO.test.a10(3,:);ELMIGWO.train.a10(3,:);ELMACOR.test.a10(4,:); ...
    ELMACOR.train.a10(4,:);ELMACOR.test.a10(3,:);ELMACOR.train.a10(3,:);ELMABC.test.a10(4,:);ELMABC.train.a10(4,:); ...
    ELMABC.test.a10(3,:);ELMABC.train.a10(3,:);ELM.test.a10(4,:);ELM.train.a10(4,:);ELM.test.a10(3,:);ELM.train.a10(3,:)];
RMSEstress=[ELMIGWO.test.RMSE(4,:);ELMIGWO.train.RMSE(4,:);ELMIGWO.test.RMSE(3,:);ELMIGWO.train.RMSE(3,:);ELMACOR.test.RMSE(4,:); ... 
    ELMACOR.train.RMSE(4,:);ELMACOR.test.RMSE(3,:);ELMACOR.train.RMSE(3,:);ELMABC.test.RMSE(4,:);ELMABC.train.RMSE(4,:); ...
    ELMABC.test.RMSE(3,:);ELMABC.train.RMSE(3,:);ELM.test.RMSE(4,:);ELM.train.RMSE(4,:);ELM.test.RMSE(3,:);ELM.train.RMSE(3,:)];
MAEstress=[ELMIGWO.test.MAE(4,:);ELMIGWO.train.MAE(4,:);ELMIGWO.test.MAE(3,:);ELMIGWO.train.MAE(3,:);ELMACOR.test.MAE(4,:); ... 
    ELMACOR.train.MAE(4,:);ELMACOR.test.MAE(3,:);ELMACOR.train.MAE(3,:);ELMABC.test.MAE(4,:);ELMABC.train.MAE(4,:); ...
    ELMABC.test.MAE(3,:);ELMABC.train.MAE(3,:);ELM.test.MAE(4,:);ELM.train.MAE(4,:);ELM.test.MAE(3,:);ELM.train.MAE(3,:)];


xvalues = {'Q1','Q2','Q3','Q4','Q5','Q6','Q7','Q8','Q9','Q10'};
ydispvalues = {'ELM-IGWO--Ydisp--test','ELM-IGWO--Ydisp--train','ELM-IGWO--Xdisp--test','ELM-IGWO--Xdisp--train', ...
    'ELM-ACOR--Ydisp--test','ELM-ACOR--Ydisp--train','ELM-ACOR--Xdisp--test','ELM-ACOR--Xdisp--train', ...
    'ELM-ABC--Ydisp--test','ELM-ABC--Ydisp--train','ELM-ABC--Xdisp--test','ELM-ABC--Xdisp--train', ...
    'ELM--Ydisp--test','ELM--Ydisp--train','ELM--Xdisp--test','ELM--Xdisp--train'};
ystressvalues = {'ELM-IGWO--Syy--test','ELM-IGWO--Syy--train','ELM-IGWO--Sxx--test','ELM-IGWO--Sxx--train', ...
    'ELM-ACOR--Syy--test','ELM-ACOR--Syy--train','ELM-ACOR--Sxx--test','ELM-ACOR--Sxx--train', ...
    'ELM-ABC--Syy--test','ELM-ABC--Syy--train','ELM-ABC--Sxx--test','ELM-ABC--Sxx--train', ...
    'ELM--Syy--test','ELM--Syy--train','ELM--Sxx--test','ELM--Sxx--train'};
wposX=100; wposY = 100;
heatmapLength = 1000;
heatmapWidth = 1000;

%------------------Effeciency figures------------------------
figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h1=heatmap(xvalues,ydispvalues,R2disp);
%h1.ColorScaling = 'scaledrows';
h1.Title = ['R^2 results for displacements & nsample' num2str(nsample)];
h1.XLabel = 'QoIs';
h1.YLabel = 'R^2 [-]';
h1.Colormap = hot;
h1.FontSize = 18;
h1.CellLabelFormat = '%.1f';
saveas(h1,[h1.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h2=heatmap(xvalues,ystressvalues,R2stress);
%h2.ColorScaling = 'scaledrows';
h2.Title = ['R^2 results for stresses & nsample' num2str(nsample)];
h2.XLabel = 'QoIs';
h2.YLabel = 'R^2 [-]';
h2.Colormap = hot;
h2.FontSize = 18;
h2.CellLabelFormat = '%.1f';
saveas(h2,[h2.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h3=heatmap(xvalues,ydispvalues,a10disp);
%h3.ColorScaling = 'scaledrows';
h3.Title = ['a10-index results for displacements & nsample' num2str(nsample)];
h3.XLabel = 'QoIs';
h3.YLabel = 'a10-index [-]';
h3.Colormap = hot;
h3.FontSize = 18;
h3.CellLabelFormat = '%.1f';
saveas(h3,[h3.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h4=heatmap(xvalues,ystressvalues,a10stress);
%h4.ColorScaling = 'scaledrows';
h4.Title = ['a10-index results for stresses & nsample' num2str(nsample)];
h4.XLabel = 'QoIs';
h4.YLabel = 'a10-index [-]';
h4.Colormap = hot;
h4.FontSize = 18;
h4.CellLabelFormat = '%.1f';
saveas(h4,[h4.Title '.png']);
close

%------------------Error figures------------------------
figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h5=heatmap(xvalues,ydispvalues,100*RMSEdisp);
%h5.ColorScaling = 'scaledrows';
h5.Title = ['RMSE results for displacements & nsample' num2str(nsample)];
h5.XLabel = 'QoIs';
h5.YLabel = '(×10^{-2}) RMSE [m]';
h5.Colormap = parula;
h5.FontSize = 18;
h5.CellLabelFormat = '%.1f';
saveas(h5,[h5.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h6=heatmap(xvalues,ystressvalues,0.001*RMSEstress);
%h6.ColorScaling = 'scaledrows';
h6.Title = ['RMSE results for stresses & nsample' num2str(nsample)];
h6.XLabel = 'QoIs';
h6.YLabel = '(×10^3) RMSE [Pa]';
h6.Colormap = parula;
h6.FontSize = 18;
h6.CellLabelFormat = '%.1f';
saveas(h6,[h6.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h7=heatmap(xvalues,ydispvalues,100*MAEdisp);
%h7.ColorScaling = 'scaledrows';
h7.Title = ['MAE results for displacements & nsample' num2str(nsample)];
h7.XLabel = 'QoIs';
h7.YLabel = '(×10^{-2}) MAE [m]';
h7.Colormap = parula;
h7.FontSize = 18;
h7.CellLabelFormat = '%.1f';
saveas(h7,[h7.Title '.png']);
close

figure('Renderer', 'painters', 'Position', [wposX wposY heatmapWidth heatmapLength]);
h8=heatmap(xvalues,ystressvalues,0.001*MAEstress);
%h8.ColorScaling = 'scaledrows';
h8.Title = ['MAE results for stresses & nsample' num2str(nsample)];
h8.XLabel = 'QoIs';
h8.YLabel = '(×10^3) MAE [Pa]';
h8.Colormap = parula;
h8.FontSize = 18;
h8.CellLabelFormat = '%.1f';
saveas(h8,[h8.Title '.png']);
close

end