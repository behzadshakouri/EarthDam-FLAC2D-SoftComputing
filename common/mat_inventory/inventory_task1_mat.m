function reportFile = inventory_task1_mat(matFile)
%INVENTORY_TASK1_MAT Inventory Task 1 data and save the report beside it.
if nargin < 1, matFile = ''; end
reportFile = inventory_task_mat('Task1',matFile);
end
