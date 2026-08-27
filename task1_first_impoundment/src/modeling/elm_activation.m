function H = elm_activation(A, name)
switch lower(name)
 case 'sigmoid', H = 1 ./ (1 + exp(-max(min(A,40),-40)));
 case 'tanh', H = tanh(A);
 otherwise, error('Unsupported ELM activation: %s', name);
end
end
