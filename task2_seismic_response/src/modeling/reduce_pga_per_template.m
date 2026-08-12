function [Xr, yr, keep] = reduce_pga_per_template(X, y, maxPGAperTemplate)
%REDUCE_PGA_PER_TEMPLATE Exact reduction used by the supplied FULL70 codes.
Xbase = X(:,1:15);
pga = X(:,16);
[~,~,gid] = unique(Xbase, 'rows', 'stable');
keep = false(size(y));
for g = 1:max(gid)
    idxg = find(gid == g);
    [~,ia] = unique(pga(idxg), 'stable');
    if numel(ia) > maxPGAperTemplate
        pick = round(linspace(1, numel(ia), maxPGAperTemplate));
        ia = ia(pick);
    end
    keep(idxg(ia)) = true;
end
Xr = X(keep,:);
yr = y(keep,:);
end
