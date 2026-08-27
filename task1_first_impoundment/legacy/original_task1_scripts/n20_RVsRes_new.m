clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision)\';

%------------------Input Matrix Generation-------------------------------
cd(Samples);
RVs=readmatrix([Samples 'RVs.xlsx']);
cd (QOIs);
load outputs_gp.mat

%output_r=[1 2 3 4 5 6 7 8 9 10]; 
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

RVsResMat=RVs;

for i=1:numel(node_row)
for mn=1:500 %model number
    cd([Maku_PT1_Models 'Maku_PT1_' num2str(mn)]);
    r=node_row(1,i);
    
    RVsResMat(mn,19)=outputs_gp(r,3,mn);
    RVsResMat(mn,20)=outputs_gp(r,4,mn);
    RVsResMat(mn,21)=outputs_gp(r,5,mn);
    RVsResMat(mn,22)=outputs_gp(r,6,mn);

end

    QOIXdisp=[RVs RVsResMat(:,19)];
    QOIYdisp=[RVs RVsResMat(:,20)];
    QOISxx=[RVs RVsResMat(:,21)];
    QOISyy=[RVs RVsResMat(:,22)];

    f='QOI_';
    folder=strcat(f,num2str(i));
    mkdir(QOIs,folder);
    cd(fullfile(QOIs,folder));
    
    filename1=['QOI_' num2str(i) '_Xdisp' '.xlsx'];
    filename2=['QOI_' num2str(i) '_Ydisp' '.xlsx'];
    filename3=['QOI_' num2str(i) '_Sxx' '.xlsx'];
    filename4=['QOI_' num2str(i) '_Syy' '.xlsx'];

    writematrix(QOIXdisp,filename1);
    writematrix(QOIYdisp,filename2);
    writematrix(QOISxx,filename3);
    writematrix(QOISyy,filename4);
    
end


