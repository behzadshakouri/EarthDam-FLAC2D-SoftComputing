function plot_task2_case_result(cr,results_dir)
%PLOT_TASK2_CASE_RESULT Save test scatter and optimizer convergence plots.
plotDir=fullfile(results_dir,'plots',cr.method);if ~exist(plotDir,'dir'),mkdir(plotDir);end
tag=sprintf('P%d_R%d',cr.point,cr.response);
if isfield(cr,'y_test')&&isfield(cr,'y_pred')&&~isempty(cr.y_test)
 v=isfinite(cr.y_test)&isfinite(cr.y_pred);
 if any(v)
  f=figure('Visible','off','Color','w');scatter(cr.y_test(v),cr.y_pred(v),8,'.');hold on
  lo=min([cr.y_test(v);cr.y_pred(v)]);hi=max([cr.y_test(v);cr.y_pred(v)]);plot([lo hi],[lo hi],'k--','LineWidth',1.2)
  axis equal;grid on;xlabel('Observed');ylabel('Predicted');title(sprintf('%s %s | R^2 = %.3f',cr.method,strrep(tag,'_','-'),cr.metrics.R2));
  exportgraphics(f,fullfile(plotDir,[tag '_observed_vs_predicted.png']),'Resolution',200);close(f)
 end
end
if isfield(cr,'history')&&~isempty(cr.history)
 f=figure('Visible','off','Color','w');semilogy(cr.history,'LineWidth',1.4);grid on;xlabel('Iteration');ylabel('Best objective');title(sprintf('%s %s convergence',cr.method,strrep(tag,'_','-')));
 exportgraphics(f,fullfile(plotDir,[tag '_convergence.png']),'Resolution',200);close(f)
end
end
