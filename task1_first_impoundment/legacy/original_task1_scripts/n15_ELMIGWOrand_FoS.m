
clc
clear all %#ok
close all

%% Input data

%------------------Adresses-------------------------------
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs\';
FoS='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\FoS\';

for nsample=[50 100 150 200 300 400 500]
    
% -----------------Reading input files--------------------
    
Comment='FoS';
Comment1='ELMIGWO_';
Comment2='ELMIGWO-Train';
Comment3='ELMIGWO-Test';

cd(FoS);
data=readmatrix('PT1_FoS_SCT.xlsx');


%------------------random selection-----------------------
drand=rand(500,1);
drandperm=randperm(500);
data=data(drandperm(1:nsample),:);
datatable=array2table(data);

input=data(:,1:end-1);
target=data(:,end);

[inputn,is]=mapminmax(input'); % Standardization in [-1, 1]
[targetn,ts]=mapminmax(target');

inputn=inputn';
targetn=targetn';
% 
ntrain=ceil(size(data,1)*0.7);
ntest=size(data,1)-ntrain;
inputtrainn=inputn(1:ntrain,:); % 70% Train, %30% Test
inputtestn=inputn(ntrain+1:end,:);
targettrainn=targetn(1:ntrain);
targettestn=targetn(ntrain+1:end);
% 
inputtest=mapminmax('reverse',inputtestn',is);
inputtrain=mapminmax('reverse',inputtrainn',is);
inputtest=inputtest';
inputtrain=inputtrain';

%% ELM running
hln=14; % 0.028*ceil(size(data,1)); % Run with determined hln
k=size(inputtrain,2);
elm=ELM('numberOfInputNeurons', k, 'numberOfHiddenNeurons',hln, 'activationFunction','sig');
elm=elm.train(inputtrainn, targettrainn);

x1=elm.inputWeight(:);
x2=elm.biasOfHiddenNeurons(:);
x3=elm.outputWeight(:);

x=[x1;x2;x3];

nnn=size(x,1);

%% Run Hybridization with IGWO
N=30;
Max_iteration=1000;

objfunc = @(x) RMSE(x, elm, inputtrainn, targettrainn,x1,x2,k,hln);

[Fbest,Lbest,Convergence_curve]=IGWO(nnn,N,Max_iteration,-1,1,objfunc);

x=Lbest';

%% ELM Outputs
elm.inputWeight=vec2mat(x(1:size(x1,1)),k)';
elm.biasOfHiddenNeurons=vec2mat(x(size(x1,1)+1:size(x1,1)+size(x2,1)),hln);
elm.outputWeight=x(size(x1,1)+size(x2,1)+1:end);

Ptrainn=elm.predict(inputtrainn);
Ptestn=elm.predict(inputtestn);

Ptrain=mapminmax('reverse',Ptrainn',ts);
Ptest=mapminmax('reverse',Ptestn',ts);
Ttrain=mapminmax('reverse',targettrainn',ts);
Ttest=mapminmax('reverse',targettestn',ts);

Ttrain=Ttrain';
Ttest=Ttest';
Ptest=Ptest';
Ptrain=Ptrain';

ELMIGWO1.Ptest=Ptest;
ELMIGWO1.Ptrain=Ptrain;
ELMIGWO1.Ttrain=Ttrain;
ELMIGWO1.Ttest=Ttest;

%% Error Calculations

Rtrain=corr(Ttrain,Ptrain);
R_squaredtrain=Rtrain^2;
Rtest=corr(Ttest,Ptest);
R_squaredtest=Rtest^2;

Errortrain=Error1(Ptrain,Ttrain);

Errortest=Error1(Ptest,Ttest);

RMSEtest=Errortest.RMSE;
RMSEtrain=Errortrain.RMSE;

%% Results
 filename1 = [Comment1 Comment '_n' num2str(nsample) '_Statistics' '.xlsx'];
      sheet=1;
      A = {'train.R2','train.RMSE','train.MAE','train.a10','test.R2','test.RMSE','test.MAE','test.a10'; Errortrain.Corkare,Errortrain.RMSE, Errortrain.MAE, Errortrain.a10,...
          Errortest.Corkare,Errortest.RMSE,Errortest.MAE,Errortest.a10};
      xlswrite(filename1,A,sheet,'A1')
      
 filename2 = [Comment1 Comment '.mat'];
 %save(filename2)
 
 filename3 = [Comment1 Comment '_n' num2str(nsample) '_Values' '.xlsx'];
 sheet=1;
  P=[ELMIGWO1.Ptrain];
  P=[P; ELMIGWO1.Ptest];
  P=array2table(P);
 writetable(datatable,filename3,'Sheet',sheet,'Range','A1','WriteVariableNames',false);
 writetable(P,filename3,'Sheet',sheet,'Range','T1','WriteVariableNames',false);

 %save(filename3);
 
end
 
 
 
 
 
 
 
      