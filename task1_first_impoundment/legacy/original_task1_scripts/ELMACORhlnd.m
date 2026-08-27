
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
Comment1='ELMACOR_';
Comment2='ELMACOR-Train';
Comment3='ELMACOR-Test';

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
maxhln=0.05*ceil(size(data,1));
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
%% Run Hybridization with ACOR
problem = ypea_problem();
nnn=size(x,1);
problem.vars = ypea_var('x', 'real', 'size', nnn, 'lower_bound', -1, 'upper_bound', 1);

% Problem Definition
RMSE = ypea_test_function('RMSE');

problem.obj_func = @(sol) RMSE(sol.x, elm, inputtrainn, targettrainn,x1,x2,k,hln);

%%
%optimization algorithms

% First, we must create an instance of algorithm class:
alg = ypea_acor();

% Maximum Number of Iterations
alg.max_iter = 1000;

% Population Size (Solution Archive Size)
alg.pop_size = 40;

% Number of Newly Generated Samples
alg.sample_count = 40;

% Intensification Factor (Selection Pressure)
alg.q = 0.1;

% Deviation-Distance Ratio
alg.zeta = 1;

%%
% And now, we are ready to run the algorithm and solve the problem.
% The solve method, gets problem as input and returns |best_sol|, the best solution found
% by the algorithm.

best_sol = alg.solve(problem);

% figure(i)
% hold on
% 
% plot(this.best_sol.obj_value,'LineWidth',2)
% semilogy(this.best_sol.obj_value,'LineWidth',2)
% 
% xlabel('Iteration');
% ylabel('Best Cost');
% grid on;


%%
% You may turn of the text output, by disabling the display property, just
% befor running the algorithm (i.e. calling |alg.solve(problem)|).
alg.display = false;

% Results

%%
% The actual solution, is stored in the |solution| field of |best_sol|.

best_sol.solution

%%
% The values of 20 decision variables, denoted by |x| is as follows:
best_sol.solution.x

%%
% and the related objective value is:
best_sol.obj_value

%%
% Total run time of the algorithm is given by (in seconds):
alg.run_time

%%
% and total number of function evaluations is given by:
alg.nfe
alg.full_name;

x=best_sol.solution.x';

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
 
ELMACOR1.Ptest=Ptest;
ELMACOR1.Ptrain=Ptrain;
ELMACOR1.Ttrain=Ttrain;
ELMACOR1.Ttest=Ttest;

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
k=size(inputtrainn,2);
elm=ELM('numberOfInputNeurons', k, 'numberOfHiddenNeurons',hln, 'activationFunction','sig');
elm=elm.train(inputtrainn, targettrainn);

x1=elm.inputWeight(:);
x2=elm.biasOfHiddenNeurons(:);
x3=elm.outputWeight(:);

x=[x1;x2;x3];

%% Run Hybridization with ACOR
problem = ypea_problem();
nnn=size(x,1);
problem.vars = ypea_var('x', 'real', 'size', nnn, 'lower_bound', -1, 'upper_bound', 1);

% Problem Definition
RMSE = ypea_test_function('RMSE');

problem.obj_func = @(sol) RMSE(sol.x, elm, inputtrainn, targettrainn,x1,x2,k,hln);

%%
%optimization algorithms

% First, we must create an instance of algorithm class:
alg = ypea_acor();

% Maximum Number of Iterations
alg.max_iter = 1000;

% Population Size (Solution Archive Size)
alg.pop_size = 40;

% Number of Newly Generated Samples
alg.sample_count = 40;

% Intensification Factor (Selection Pressure)
alg.q = 0.1;

% Deviation-Distance Ratio
alg.zeta = 1;

%%
% And now, we are ready to run the algorithm and solve the problem.
% The solve method, gets problem as input and returns |best_sol|, the best solution found
% by the algorithm.

best_sol = alg.solve(problem);

% figure(i)
% hold on
% 
% plot(this.best_sol.obj_value,'LineWidth',2)
% semilogy(this.best_sol.obj_value,'LineWidth',2)
% 
% xlabel('Iteration');
% ylabel('Best Cost');
% grid on;


%%
% You may turn of the text output, by disabling the display property, just
% befor running the algorithm (i.e. calling |alg.solve(problem)|).
alg.display = false;

% Results

%%
% The actual solution, is stored in the |solution| field of |best_sol|.

best_sol.solution

%%
% The values of 20 decision variables, denoted by |x| is as follows:
best_sol.solution.x

%%
% and the related objective value is:
best_sol.obj_value

%%
% Total run time of the algorithm is given by (in seconds):
alg.run_time

%%
% and total number of function evaluations is given by:
alg.nfe
alg.full_name;

x=best_sol.solution.x';

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

ELMACOR1.Ptest=Ptest;
ELMACOR1.Ptrain=Ptrain;
ELMACOR1.Ttrain=Ttrain;
ELMACOR1.Ttest=Ttest;

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
  P=[ELMACOR1.Ptrain];
  P=[P; ELMACOR1.Ptest];
  P=array2table(P);

 writetable(datatable,filename3,'Sheet',sheet,'Range','A1','WriteVariableNames',false);
 writetable(P,filename3,'Sheet',sheet,'Range','S1','WriteVariableNames',false);
 %save(filename3);
 
end
end
 
 
 
 
 
 
 
 
 
 
      