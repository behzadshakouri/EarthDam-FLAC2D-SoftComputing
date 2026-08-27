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
load FoS_results5.mat

for nsample=[50 100 150 200 300 400 500]
    
%-----------------Reading input files--------------------
    
Comment='FoS';
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';


for a=1:4 %methods
    
if a==1
    a1='ELM';
    FDM_ELM_FoSdata=readmatrix([a1 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELM_FoSdata(:,19),FDM_ELM_FoSdata(:,20),'ko');
    hold on
    figname = ['ELM FoS & n' num2str(nsample)];
    xlabel('Calculated FoS by FDM');
    ylabel('Predicted FoS by ELM');
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELM_FoSdata(:,19)), 1.1*max(FDM_ELM_FoSdata(:,19))];
%     Y=[0.9*min(FDM_ELM_FoSdata(:,19)), 1.1*max(FDM_ELM_FoSdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM');
    saveas(fig,[figname '.png']);
    close
elseif a==2
    a2='ELMABC';
    FDM_ELMABC_FoSdata=readmatrix([a2 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMABC_FoSdata(:,19),FDM_ELMABC_FoSdata(:,20),'ko');
    figname = ['ELM-ABC FoS & n' num2str(nsample)];
    hold on
    xlabel('Calculated FoS by FDM');
    ylabel('Predicted FoS by ELM-ABC');
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMABC_FoSdata(:,19)), 1.1*max(FDM_ELMABC_FoSdata(:,19))];
%     Y=[0.9*min(FDM_ELMABC_FoSdata(:,19)), 1.1*max(FDM_ELMABC_FoSdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ABC');
    saveas(fig,[figname '.png']);
    close
elseif a==3
    a3='ELMACOR';
    FDM_ELMACOR_FoSdata=readmatrix([a3 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMACOR_FoSdata(:,19),FDM_ELMACOR_FoSdata(:,20),'ko');
    figname = ['ELM-ACOR FoS & n' num2str(nsample)];
    hold on
    xlabel('Calculated FoS by FDM');
    ylabel('Predicted FoS by ELM-ACOR');
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMACOR_FOSdata(:,19)), 1.1*max(FDM_ELMACOR_FOSdata(:,19))];
%     Y=[0.9*min(FDM_ELMACOR_FOSdata(:,19)), 1.1*max(FDM_ELMACOR_FOSdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-ACOR');
    saveas(fig,[figname '.png']);
    close
elseif a==4
    a4='ELMIGWO';
    FDM_ELMIGWO_FoSdata=readmatrix([a4 '_FoS_n' num2str(nsample) '_Values' '.xlsx']);
    fig=figure;
    plot(FDM_ELMIGWO_FoSdata(:,19),FDM_ELMIGWO_FoSdata(:,20),'ko');
    figname = ['ELM-IGWO FoS & n' num2str(nsample)];
    hold on
    xlabel('Calculated FoS by FDM');
    ylabel('Predicted FoS by ELM-IGWO');
    title(figname);
    axis equal;
    hline = refline([1 0]);
    hline.Color = 'k';
%     X=[0.9*min(FDM_ELMIGWO_FOSdata(:,19)), 1.1*max(FDM_ELMIGWO_FOSdata(:,19))];
%     Y=[0.9*min(FDM_ELMIGWO_FOSdata(:,19)), 1.1*max(FDM_ELMIGWO_FOSdata(:,19))];
%     plot(X,Y,'k-');
    legend('FDM--ELM-IGWO');
    saveas(fig,[figname '.png']);
    close
end

end

end
