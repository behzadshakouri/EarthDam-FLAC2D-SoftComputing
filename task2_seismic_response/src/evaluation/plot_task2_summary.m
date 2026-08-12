function plot_task2_summary(results,results_dir)
%PLOT_TASK2_SUMMARY Save 10-by-7 R2/nRMSE heatmaps for each model.
plotDir=fullfile(results_dir,'plots','summary');if ~exist(plotDir,'dir'),mkdir(plotDir);end
methods=unique(string(results.model),'stable');metrics={'R2','nRMSE','nMAE','a10'};
for im=1:numel(methods)
 T=results(string(results.model)==methods(im),:);
 for j=1:numel(metrics)
  Z=nan(10,7);for k=1:height(T),Z(T.point(k),T.response(k))=T.(metrics{j})(k);end
  f=figure('Visible','off','Color','w');imagesc(Z);colorbar;axis image;xticks(1:7);yticks(1:10);xlabel('Response');ylabel('Point');title(sprintf('%s %s',methods(im),metrics{j}));
  exportgraphics(f,fullfile(plotDir,sprintf('%s_%s_heatmap.png',methods(im),metrics{j})),'Resolution',200);close(f)
 end
end
end
