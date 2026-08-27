clc
clear all %#ok
close all

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';

%------------------Input Matrix Generation-------------------------------
cd(Samples);
RVs=readmatrix([Samples 'RVs.xlsx']);

for mn=1:500 %model number
    cd([Maku_PT1_Models 'Maku_PT1_' num2str(mn)]);
    outputs_gp(:,:,mn)=readmatrix('outputs_gp.xlsx'); %#ok
end

cd(Soft_Computing);
save outputs_gp.mat;
