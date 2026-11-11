function Y=predict_task3_compact_all70(models,X,recordId)
%PREDICT_TASK3_COMPACT_ALL70 Run ten point models and return P1R1...P10R7.
assert(iscell(models)&&numel(models)==10,'Expected ten point-wise FMRVR models.');
Y=zeros(size(X,1),70);
for point=1:10
    cols=(point-1)*7+(1:7);
    Y(:,cols)=predict_task3_compact_pointwise_fmrvr(models{point},X);
end
if nargin>=3
    for id=unique(recordId(:))'
        rows=find(recordId==id);Y(rows,:)=cummax(max(Y(rows,:),0),1);
    end
end
end
