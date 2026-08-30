function reportFile = inventory_task3_mat(matFile)
%INVENTORY_TASK3_MAT Inventory Task 3 data and save the report beside it.
if nargin < 1, matFile = ''; end
reportFile = inventory_task_mat('Task3',matFile);
end
