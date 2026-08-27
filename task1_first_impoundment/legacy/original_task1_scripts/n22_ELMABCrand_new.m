
clc
clear all %#ok
close all

%% Input data

%------------------Adresses-------------------------------
Samples='E:\University\My Thesis\Flac model\Maku_PT1\RVs_Static\Samples\';
Maku_PT1_Models='E:\University\My Thesis\Flac model\Maku_PT1\Maku_PT1_Models\';
Soft_Computing='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\';
QOIs='E:\University\My Thesis\Flac model\Maku_PT1\Soft Computing\QOIs (paper-revision)\';

for nsample=[50 100 150 200 300 400 500]

%-----------------Reading input files--------------------
node_row(1,:)=[14173 14198 14223 11469 11494 11519 16877 16902 16927 14455];

Res{1,1}='Xdisp';
Res{1,2}='Ydisp';
Res{1,3}='Sxx';
Res{1,4}='Syy';

for i=10:numel(node_row)

    f='n';
    folder=strcat(f,num2str(nsample));
    QOIn=[QOIs 'QOI_' num2str(i) '\'];
    cd(QOIn);
    mkdir(QOIn,folder);

for j=1:4
    
Comment=['QOI_' num2str(i) '_' Res{1,j}];
Comment1='ELMABC_';
Comment2='ELMABC-Train';
Comment3='ELMABC-Test';

data=readmatrix([Comment '.xlsx']);
cd([QOIn '\n' num2str(nsample) '\']);


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
hln=2; % 0.004*ceil(size(data,1)); % Run with determined hln
k=size(inputtrain,2);
elm=ELM('numberOfInputNeurons', k, 'numberOfHiddenNeurons',hln, 'activationFunction','sig');
elm=elm.train(inputtrainn,targettrainn);

x1=elm.inputWeight(:);
x2=elm.biasOfHiddenNeurons(:);
x3=elm.outputWeight(:);

x=[x1;x2;x3];

%% Run Hybridization with ABC

problem = ypea_problem();
%problem.type = 'min';
nnn=size(x,1);
problem.vars = ypea_var('x', 'real', 'size', nnn, 'lower_bound', -1, 'upper_bound', 1);

% Problem Definition
RMSE = ypea_test_function('RMSE'); %uygunluk fonksiyonu

problem.obj_func = @(sol) RMSE(sol.x, elm, inputtrainn, targettrainn,x1,x2,k,hln);

% optimization algorithms

%%
% First, we must create an instance of algorithm class:
alg = ypea_abc();

% Maximum Number of Iterations
alg.max_iter = 1000;

% Population Size
alg.pop_size = 30;

% Number of Onlooker Bees
alg.onlooker_count = 20;

% Maximum Acceleration
alg.max_acceleration = 0.4;

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
 
ELMABC1.Ptest=Ptest;
ELMABC1.Ptrain=Ptrain;
ELMABC1.Ttrain=Ttrain;
ELMABC1.Ttest=Ttest;

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
  P=[ELMABC1.Ptrain];
  P=[P; ELMABC1.Ptest];
  P=array2table(P);
  
 writetable(datatable,filename3,'Sheet',sheet,'Range','A1','WriteVariableNames',false);
 writetable(P,filename3,'Sheet',sheet,'Range','T1','WriteVariableNames',false);
 cd(QOIn);

 %save(filename3);
 
end
end

end
 
 
 
 
 
 
 
 
 
 
      