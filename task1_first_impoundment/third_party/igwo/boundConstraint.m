function vi = boundConstraint(vi,pop,lu)
%BOUNDCONSTRAINT I-GWO/L-SHADE midpoint boundary repair.
% Distributed under the I-GWO BSD-style license in this directory.
[NP,~] = size(pop);
xl = repmat(lu(1,:),NP,1);
pos = vi < xl;
vi(pos) = (pop(pos)+xl(pos))/2;
xu = repmat(lu(2,:),NP,1);
pos = vi > xu;
vi(pos) = (pop(pos)+xu(pos))/2;
end
