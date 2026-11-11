function dictionary = task4_response_dictionary()
%TASK4_RESPONSE_DICTIONARY Canonical P-major response ordering.
names = {'Xdisp','Ydisp','Sxx','Syy','Ppore','ssi','vsi'};
units = {'m','m','Pa','Pa','Pa','-','-'};
dictionary = struct('case_id',{},'point',{},'response',{},'name',{},'unit',{},'label',{});
k = 0;
for p = 1:10
    for r = 1:7
        k = k+1;
        dictionary(k).case_id = k;
        dictionary(k).point = p;
        dictionary(k).response = r;
        dictionary(k).name = names{r};
        dictionary(k).unit = units{r};
        dictionary(k).label = sprintf('P%dR%d',p,r);
    end
end
end
