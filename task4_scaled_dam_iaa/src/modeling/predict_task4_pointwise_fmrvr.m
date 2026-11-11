function Y=predict_task4_pointwise_fmrvr(models,X,recordId)
%PREDICT_TASK4_POINTWISE_FMRVR One-call prediction of all 70 responses.
assert(iscell(models)&&numel(models)==10,'Ten point-wise FMRVR models are required.');
Y=zeros(size(X,1),70);
for point=1:10
    cols=(point-1)*7+(1:7);
    Y(:,cols)=predict_task4_fmrvr_peak(models{point},X);
end
Y=max(Y,0);
if nargin>=3 && ~isempty(recordId)
    for id=unique(recordId(:))'
        rows=find(recordId==id);Y(rows,:)=cummax(Y(rows,:),1);
    end
end
end
