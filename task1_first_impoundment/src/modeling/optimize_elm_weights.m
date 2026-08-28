function [best_x, history] = optimize_elm_weights(method, x0, lb, ub, costfun, opt, progress)
%OPTIMIZE_ELM_WEIGHTS Dispatch only to optimizers used by supplied codes.
if nargin < 7, progress = struct(); end %#ok<NASGU>
method = upper(string(method)); n = numel(x0);
switch method
    case "ELMABC"
        require_ypea({'ypea_problem','ypea_var','ypea_abc'});
        problem=ypea_problem();
        problem.vars=ypea_var('x','real','size',n,'lower_bound',lb,'upper_bound',ub);
        problem.obj_func=@(sol) costfun(sol.x(:));
        alg=ypea_abc(); alg.max_iter=opt.max_iter; alg.pop_size=opt.pop_size;
        alg.onlooker_count=opt.onlooker_count; alg.max_acceleration=opt.max_acceleration;
        alg.display=true; best_sol=alg.solve(problem);
        best_x=best_sol.solution.x(:); history=extract_ypea_history(best_sol);
    case "ELMACOR"
        require_ypea({'ypea_problem','ypea_var','ypea_acor'});
        problem=ypea_problem();
        problem.vars=ypea_var('x','real','size',n,'lower_bound',lb,'upper_bound',ub);
        problem.obj_func=@(sol) costfun(sol.x(:));
        alg=ypea_acor(); alg.max_iter=opt.max_iter; alg.pop_size=opt.pop_size;
        alg.sample_count=opt.sample_count; alg.q=opt.q; alg.zeta=opt.zeta;
        alg.display=true; best_sol=alg.solve(problem);
        best_x=best_sol.solution.x(:); history=extract_ypea_history(best_sol);
    case "ELMIGWO"
        require_igwo_dependencies();
        [~,best_x,history]=IGWO(n,opt.pop_size,opt.max_iter,lb,ub,@(x) costfun(x(:)));
        best_x=best_x(:); history=history(:);
    otherwise
        error('Task1:UnknownOptimizer','Unknown method %s.',method);
end
end

function require_igwo_dependencies()
names={'IGWO','initialization','boundConstraint','pdist','pdist2','squareform'};
missing=names(cellfun(@(f) exist(f,'file')==0,names));
if ~isempty(missing)
    error('Task1:MissingIGWODependency','Missing I-GWO dependencies: %s.',strjoin(missing,', '));
end
end

function require_ypea(names)
missing=names(cellfun(@(f) exist(f,'file')==0,names));
if ~isempty(missing)
    error('Task1:MissingYPEA','Missing YPEA dependencies: %s.',strjoin(missing,', '));
end
end

function h=extract_ypea_history(s)
h=[]; names={'best_costs','best_cost','history','cost_history'};
for i=1:numel(names)
    if isstruct(s) && isfield(s,names{i}) && isnumeric(s.(names{i}))
        h=s.(names{i})(:); return
    end
    try
        v=s.(names{i}); if isnumeric(v), h=v(:); return, end
    catch
    end
end
end
