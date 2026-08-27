function RMSE_calc = RMSE(wb, elm, input, target,x1,x2,k,t)


elm.inputWeight=vec2mat(wb(1:size(x1,1)),k)';
elm.biasOfHiddenNeurons=vec2mat(wb(size(x1,1)+1:size(x1,1)+size(x2,1)),t);
elm.outputWeight=wb(size(x1,1)+size(x2,1)+1:end)';



% wb is the weights and biases row vector obtained from the genetic algorithm.

% It must be transposed when transferring the weights and biases to the network net.

%  net = setwb(net, wb');

% The net output matrix is given by net(input). The corresponding error matrix is given by

 error = target - elm.predict(input);

% The mean squared error normalized by the mean target variance is

 NMSE_calc = mean(error.^2)/mean(var(target',1));
 
 RMSE_calc=((mean(sum(error.^2)))^0.5);

% It is independent of the scale of the target components and related to the Rsquare statistic via

% Rsquare = 1 - NMSEcalc ( see Wikipedia)




