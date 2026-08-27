
clc
clear all %#ok
close all

%% Input data

%------------------Adresses-------------------------------
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\';

%-----------------Reading input files--------------------
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for i=1:numel(node_row)
cd([QOIs 'QOI_' num2str(i)]);

for j=1:4
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];
Comment1='ELM_';
Comment2='ELM-Train';
Comment3='ELM-Test';

data=readmatrix([Comment '.xlsx']);
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
hln=16; % 0.05*ceil(size(data,1)); % Run with determined hln
k=size(inputtrain,2);
elm=ELM('numberOfInputNeurons', k, 'numberOfHiddenNeurons',hln, 'activationFunction','sig');
elm=elm.train(inputtrainn,targettrainn);

x1=elm.inputWeight(:);
x2=elm.biasOfHiddenNeurons(:);
x3=elm.outputWeight(:);

x=[x1;x2;x3];

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
 
ELM1.Ptest=Ptest;
ELM1.Ptrain=Ptrain;
ELM1.Ttrain=Ttrain;
ELM1.Ttest=Ttest;
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

 filename1 = [Comment1 Comment '_Statistics' '.xlsx'];
      sheet=1;
      A = {'train.R2','train.RMSE','train.MAE','train.a10','test.R2','test.RMSE','test.MAE','test.a10'; Errortrain.Corkare,Errortrain.RMSE, Errortrain.MAE, Errortrain.a10,...
          Errortest.Corkare,Errortest.RMSE,Errortest.MAE,Errortest.a10};
      xlswrite(filename1,A,sheet,'A1')
      
 filename2 = [Comment1 Comment '.mat'];
  %save(filename2)
 
 filename3 = [Comment1 Comment '_Values' '.xlsx'];
 sheet=1;
  %B={'ELMPtrain','ELMPtest','ELMTtrain','ELMTtest';ELM.Ptrain,ELM.Ptest,ELM.Ttrain,ELM.Ttest};
  P=[ELM1.Ptrain];
  P=[P; ELM1.Ptest];
  P=array2table(P);
  %datatable=[datatable; P];
  %datatable=array2table(datatable);
  %xlswrite(filename3,B,sheet,'A1');
 writetable(datatable,filename3,'Sheet',sheet,'Range','A1','WriteVariableNames',false);
 writetable(P,filename3,'Sheet',sheet,'Range','S1','WriteVariableNames',false);
  %save(filename3);
 
end
end
 
 
 
 
 
 
 
 
 
      