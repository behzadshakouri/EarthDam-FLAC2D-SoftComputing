function reportFile = inventory_task2_mat(matFile)
%INVENTORY_TASK2_MAT Inventory Task 2 data and save the report beside it.
if nargin < 1, matFile = ''; end
reportFile = inventory_task_mat('Task2',matFile);
end
