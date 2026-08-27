
clc
clear all %#ok
close all

%% Input data

%------------------Adresses-------------------------------
Maku_PT1_Models='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis - Working\Flac model\Maku Final\Maku_PT1\Soft Computing\QOIs\';

%-----------------Reading input files--------------------
node_row(1,:)=[13680];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for ii=1:numel(node_row)
cd([QOIs 'QOI_' num2str(ii)]);

for jj=1:4
    
Comment=['QOI_' num2str(ii) '_' Res{1,jj}];
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

%% ELM running for determining optimized hidden layer neurons
maxhln=0.5*ceil(size(data,1));
i=1;
while i<=maxhln
hln=i;
k=size(inputtrain,2);
elm=ELM('numberOfInputNeurons', k, 'numberOfHiddenNeurons',hln, 'activationFunction','sig');
elm=elm.train(inputtrainn,targettrainn);

x1=elm.inputWeight(:);
x2=elm.biasOfHiddenNeurons(:);
x3=elm.outputWeight(:);

x=[x1;x2;x3];
% ELM Outputs
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
R_squaredtrain(i,1)=Rtrain^2; %#ok
Rtest=corr(Ttest,Ptest);
R_squaredtest(i,1)=Rtest^2;   %#ok
R_squareddelta(i,1)=R_squaredtrain(i,1)-R_squaredtest(i,1); %#ok 

Errortrain=Error1(Ptrain,Ttrain); %#ok

Errortest=Error1(Ptest,Ttest); %#ok

i=i+1;
end

Rsdf=find ((abs(R_squareddelta))<0.15);
for m=Rsdf
    Rsdfm=Rsdf;
    Rsdfm=[Rsdfm R_squaredtrain(m,1) R_squaredtest(m,1)]; %#ok
    [Rstr_opt, hlntr_optn]=max(Rsdfm(:,2));
hlntr_opt=Rsdfm(hlntr_optn,1);
[Rste_opt, hlnte_optn]=max(Rsdfm(:,3));
hlnte_opt=Rsdfm(hlnte_optn,1);
hln_opt=min(hlntr_opt,hlnte_opt);
end

j=1:1:maxhln;
figure1=figure;
set(gcf, 'PaperUnits', 'centimeters');
set(gcf, 'PaperSize', [24 6]);
plot(j,R_squaredtrain,'-o','DisplayName','R Squared Train');
hold on;
plot(j,R_squaredtest,'-*','DisplayName','R Squared Test');
plot(j,R_squareddelta,'--','DisplayName','R Squared Delta');
plot(hlntr_opt,R_squaredtrain(hlntr_opt,1),'-s','DisplayName','Selected Node Train','MarkerSize',15,'MarkerEdgeColor','b');
plot(hlnte_opt,R_squaredtest(hlnte_opt,1),'-s','DisplayName','Selected Node Test','MarkerSize',15,'MarkerEdgeColor','b');
plot(hln_opt,R_squaredtrain(hln_opt,1),'-s','DisplayName','Optimum Node Train','MarkerSize',15,'MarkerEdgeColor','m');
plot(hln_opt,R_squaredtest(hln_opt,1),'-s','DisplayName','Optimum Node Test','MarkerSize',15,'MarkerEdgeColor','m');
title([Comment1 ' HLNN Selection for QOI' num2str(ii) Res{1,jj}]);
xlabel('Hidden Layer Neurons Number (HLNN)');
ylabel('R Squared');
legend('Location','best');
saveas(figure1,[Comment1 ' HLNN Selection for ' Comment '.png']);
%figure
%plot(R_squareddelta,R_squaredtrain);
%% ELM running with optimized and automated hln
hln=hln_opt; % optimized and automated hln
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
      A = {'train.R2','train.RMSE','train.MAE','train.a10','test.R2','test.RMSE','test.MAE','test.a10','hln_opt'; Errortrain.Corkare,Errortrain.RMSE, Errortrain.MAE, Errortrain.a10,...
          Errortest.Corkare,Errortest.RMSE,Errortest.MAE,Errortest.a10,hln_opt};
      xlswrite(filename1,A,sheet,'A1')
      
 filename2 = [Comment1 Comment '.mat'];
  %save(filename2)
 
 filename3 = [Comment1 Comment '_Values' '.xlsx'];
 sheet=1;
  P=[ELM1.Ptrain];
  P=[P; ELM1.Ptest];
  P=array2table(P);
  
 writetable(datatable,filename3,'Sheet',sheet,'Range','A1','WriteVariableNames',false);
 writetable(P,filename3,'Sheet',sheet,'Range','S1','WriteVariableNames',false);
  %save(filename3);
 
end
end
      