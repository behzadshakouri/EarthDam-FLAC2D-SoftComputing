function dictionary = task3_response_dictionary()
%TASK3_RESPONSE_DICTIONARY Canonical P-major output ordering.
names = {'Horizontal displacement','Vertical displacement', ...
    'Horizontal normal stress','Vertical normal stress', ...
    'Pore-water pressure','Incremental shear strain', ...
    'Incremental volumetric strain'};
symbols = {'Delta_x','Delta_y','sigma_xx','sigma_yy','P_pore','delta_gamma','delta_nu_s'};
units = {'m','m','Pa','Pa','Pa','-','-'};
dictionary = struct('column',{},'point',{},'response',{},'name',{}, ...
    'symbol',{},'unit',{},'label',{});
k = 0;
for p = 1:10
    for r = 1:7
        k = k + 1;
        dictionary(k).column = k;
        dictionary(k).point = p;
        dictionary(k).response = r;
        dictionary(k).name = names{r};
        dictionary(k).symbol = symbols{r};
        dictionary(k).unit = units{r};
        dictionary(k).label = sprintf('P%dR%d', p, r);
    end
end
end
