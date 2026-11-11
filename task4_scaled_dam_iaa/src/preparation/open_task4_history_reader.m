function [reader, cleanup] = open_task4_history_reader(file,cfg)
%OPEN_TASK4_HISTORY_READER Read v7.3 cell histories without loading the database.
fid=H5F.open(file,'H5F_ACC_RDONLY','H5P_DEFAULT');
cleanup=onCleanup(@() H5F.close(fid));
assert(h5read(file,'/Task4/Inputs/Simulations')==cfg.num_simulations);
assert(h5read(file,'/Task4/Outputs/Simulations')==cfg.num_simulations);
refs=containers.Map;
paths={'/Task4/Outputs/dytime'};
for p=1:cfg.num_points
    for r=1:cfg.num_responses
        paths{end+1}=sprintf('/Task4/Outputs/P%d/R%d',p,r); %#ok<AGROW>
    end
end
for j=1:numel(paths)
    did=H5D.open(fid,paths{j});
    closeDataset=onCleanup(@() H5D.close(did));
    value=H5D.read(did); clear closeDataset;
    assert(size(value,2)==cfg.num_simulations,'Task4:InvalidCellCount', ...
        'Unexpected cell count at %s.',paths{j});
    refs(paths{j})=value;
end
reader=@readHistory;
    function value=readHistory(path,index)
        allRefs=refs(path);
        did=H5R.dereference(fid,'H5R_OBJECT',allRefs(:,index));
        closeDataset=onCleanup(@() H5D.close(did));
        value=double(H5D.read(did)); value=value(:);
    end
end
