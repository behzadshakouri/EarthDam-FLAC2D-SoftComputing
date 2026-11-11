function value = task3_median_distance(X)
%TASK3_MEDIAN_DISTANCE Median nonzero pairwise Euclidean distance.
n = size(X,1); distances = zeros(n*(n-1)/2,1); k = 0;
for i = 1:n-1
    d = sqrt(sum(bsxfun(@minus,X(i+1:end,:),X(i,:)).^2,2));
    distances(k+1:k+numel(d)) = d; k = k + numel(d);
end
distances = distances(isfinite(distances) & distances > 0);
assert(~isempty(distances), 'Cannot estimate a kernel width from identical inputs.');
value = median(distances);
end
