function paths = generate_task3_screening_sensitivity_figure(outputDir)
%GENERATE_TASK3_SCREENING_SENSITIVITY_FIGURE Appendix screening diagnostic.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_task3;
if nargin<1||isempty(outputDir)
    outputDir=fullfile(task3_output_root(root),'figures');
end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
source=fullfile(task3_analysis_results_root(root),'screening_sensitivity.csv');
sensitivity=readtable(source);

f=figure('Visible','off','Color','w','Position',[100 100 780 450]);
values=[sensitivity.p95_relative_target_change sensitivity.maximum_relative_target_change];
labels=string(sensitivity.threshold_multiplier)+'x';
b=bar(categorical(labels,labels),values,'grouped');
b(1).FaceColor=[0 .447 .741];b(2).FaceColor=[.85 .325 .098];grid on;
xlabel('Runaway-threshold multiplier');
ylabel('Relative change from 5x targets');
legend('95th percentile','Maximum','Location','northwest','Box','off');
set(gca,'FontName','Arial','FontSize',10.5,'TickDir','out','LineWidth',.8, ...
    'GridAlpha',.16);ylim([0 1.08*max(values,[],'all')]);
for series=1:2
    for row=1:height(sensitivity)
        text(row+(series-1.5)*.22,values(row,series)+.025*max(values,[],'all'), ...
            sprintf('%.2f',values(row,series)),'HorizontalAlignment','center', ...
            'FontName','Arial','FontSize',9);
    end
end
paths.pdf=fullfile(outputDir,'screening_sensitivity.pdf');
paths.crop_pdf=fullfile(outputDir,'screening_sensitivity_crop.pdf');
paths.png=fullfile(outputDir,'screening_sensitivity.png');
exportgraphics(f,paths.pdf,'ContentType','vector');
exportgraphics(f,paths.crop_pdf,'ContentType','vector');
exportgraphics(f,paths.png,'Resolution',300);close(f);
end
