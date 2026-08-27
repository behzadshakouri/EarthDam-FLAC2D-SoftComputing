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
cd(Results);
load results5.mat

for nsample=[50 100 150 200 300 400 500]
    
%-----------------Reading input files--------------------
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for i=1:numel(node_row) %node numbers

for j=1:4 %responses
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';

QOIn=[QOIs 'QOI_' num2str(i)];
cd([QOIn '\n' num2str(nsample) '\']);

for a=1:4 %methods
    
if a==1
    a1='ELM';
    FDM_ELMdata=readmatrix([a1 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMdata(:,19),FDM_ELMdata(:,20),'ko');
    hold on
    figname = ['ELM ' Res{1,j} ' & QoI' num2str(i) ' & n' num2str(nsample)];
    xlabel(['Calculated ' Res{1,j} ' by FDM']);
    ylabel(['Predicted ' Res{1,j} ' by ELM']);
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMdata(:,19)), 1.1*max(FDM_ELMdata(:,19))];
%     Y=[0.9*min(FDM_ELMdata(:,19)), 1.1*max(FDM_ELMdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM');
    saveas(fig,[figname '.png']);
    close
elseif a==2
    a2='ELMABC';
    FDM_ELMABCdata=readmatrix([a2 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMABCdata(:,19),FDM_ELMABCdata(:,20),'ko');
    figname = ['ELM-ABC ' Res{1,j} ' & QoI' num2str(i) ' & n' num2str(nsample)];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM']);
    ylabel(['Predicted ' Res{1,j} ' by ELM-ABC']);
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMABCdata(:,19)), 1.1*max(FDM_ELMABCdata(:,19))];
%     Y=[0.9*min(FDM_ELMABCdata(:,19)), 1.1*max(FDM_ELMABCdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ABC');
    saveas(fig,[figname '.png']);
    close
elseif a==3
    a3='ELMACOR';
    FDM_ELMACORdata=readmatrix([a3 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMACORdata(:,19),FDM_ELMACORdata(:,20),'ko');
    figname = ['ELM-ACOR ' Res{1,j} ' & QoI' num2str(i) ' & n' num2str(nsample)];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM']);
    ylabel(['Predicted ' Res{1,j} ' by ELM-ACOR']);
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMACORdata(:,19)), 1.1*max(FDM_ELMACORdata(:,19))];
%     Y=[0.9*min(FDM_ELMACORdata(:,19)), 1.1*max(FDM_ELMACORdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ACOR');
    saveas(fig,[figname '.png']);
    close
elseif a==4
    a4='ELMIGWO';
    FDM_ELMIGWOdata=readmatrix([a4 '_QOI_' num2str(i) '_' Res{1,j} '_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMIGWOdata(:,19),FDM_ELMIGWOdata(:,20),'ko');
    figname = ['ELM-IGWO ' Res{1,j} ' & QoI' num2str(i) ' & n' num2str(nsample)];
    hold on
    xlabel(['Calculated ' Res{1,j} ' by FDM']);
    ylabel(['Predicted ' Res{1,j} ' by ELM-IGWO']);
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMIGWOdata(:,19)), 1.1*max(FDM_ELMIGWOdata(:,19))];
%     Y=[0.9*min(FDM_ELMIGWOdata(:,19)), 1.1*max(FDM_ELMIGWOdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-IGWO');
    saveas(fig,[figname '.png']);
    close
end

end

end
end
end