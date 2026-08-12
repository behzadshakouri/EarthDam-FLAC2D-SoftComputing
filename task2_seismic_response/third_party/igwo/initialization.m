function Positions = initialization(SearchAgents_no,dim,ub,lb)
%INITIALIZATION Original I-GWO population initialization helper.
% Distributed under the I-GWO BSD-style license in this directory.
if isscalar(ub)
    Positions = rand(SearchAgents_no,dim).*(ub-lb)+lb;
else
    Positions = zeros(SearchAgents_no,dim);
    for i=1:dim
        Positions(:,i)=rand(SearchAgents_no,1).*(ub(i)-lb(i))+lb(i);
    end
end
end
