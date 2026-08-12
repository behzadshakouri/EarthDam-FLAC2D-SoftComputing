function generate_neuron_sweep_plots(summary_file)
%GENERATE_NEURON_SWEEP_PLOTS Accuracy and runtime sensitivity figures.
root=setup_task2;
if nargin<1||isempty(summary_file)
    live=fullfile(root,'results','method_neuron_sweep','method_neuron_sweep_summary.csv');
    reference=fullfile(root,'reference_results','method_neuron_sweep_summary.csv');
    if isfile(live),summary_file=live;else,summary_file=reference;end
end
T=readtable(summary_file); outDir=fullfile(root,'results','neuron_sweep_plots');
if ~isfolder(outDir),mkdir(outDir);end
methods={'ELM','ELMABC','ELMACOR','ELMIGWO'};
labels={'ELM','ELM-ABC','ELM-ACOR','ELM-IGWO'};
metrics={'mean_R2','mean_nRMSE','mean_nMAE','mean_a10'};
ylabels={'Mean R^2','Mean nRMSE','Mean nMAE','Mean a10'};
for j=1:numel(metrics)
    f=figure('Visible','off','Color','w','Position',[100 100 900 620]);hold on;
    for i=1:numel(methods)
        q=strcmpi(string(T.method),methods{i});
        plot(T.hidden_neurons(q),T.(metrics{j})(q),'-o','LineWidth',1.7, ...
            'MarkerSize',7,'DisplayName',labels{i});
    end
    grid on;xlabel('Hidden neurons');ylabel(ylabels{j});legend('Location','best');
    exportgraphics(f,fullfile(outDir,[metrics{j} '_vs_neurons.png']),'Resolution',220);close(f);
end
f=figure('Visible','off','Color','w','Position',[100 100 900 620]);hold on;
for i=1:numel(methods)
    q=strcmpi(string(T.method),methods{i});
    semilogy(T.hidden_neurons(q),T.total_train_s(q),'-o','LineWidth',1.7, ...
        'MarkerSize',7,'DisplayName',labels{i});
end
grid on;xlabel('Hidden neurons');ylabel('Measured training time (s, log scale)');
legend('Location','best');
exportgraphics(f,fullfile(outDir,'training_time_vs_neurons.png'),'Resolution',220);close(f);
fprintf('Neuron-sweep plots saved under %s\n',outDir);
end
