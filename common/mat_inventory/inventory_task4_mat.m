function reportFile = inventory_task4_mat(matFile)
%INVENTORY_TASK4_MAT Inventory Task 4 data and save the report beside it.
if nargin < 1, matFile = ''; end
reportFile = inventory_task_mat('Task4',matFile);
end
