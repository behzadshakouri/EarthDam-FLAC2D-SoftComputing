function run_synthetic_self_test()
%RUN_SYNTHETIC_SELF_TEST Validate mapping and QC without private data.
root=setup_task4(); cfg=task4_config(root); metadata=build_task4_metadata(cfg);
assert(all(metadata.scale_factor(1:150)==0.25));
assert(all(metadata.scale_factor(151:300)==0.50));
assert(all(metadata.scale_factor(301:450)==1.50));
[cleaned,info]=clean_task4_history([1 2 -1e35 4],cfg);
assert(isequal(cleaned,[1;2]) && info.was_truncated && info.first_invalid_index==3);
assert(~cfg.cross_scale_matching_confirmed);
% An isolated initial NaN is discarded as a paired sample, as in Task 2.
t=(0:0.001:20)'; y=ones(size(t)); y(1)=NaN;
[env,mask,info]=prepare_task4_history(t,y,6,cfg);
assert(all(env==1) && all(mask) && info.removed_nonfinite_pairs==1);
% Sentinel interpolation support and subsequent rows must never be admissible.
y=ones(size(t)); y(t>=10)=1e35;
[~,mask,info]=prepare_task4_history(t,y,6,cfg);
assert(any(mask) && ~any(mask(cfg.time_s>=10)) && info.onset_time_s<=10);
% A confirmed failed tail can be padded to the supplied time vector's end.
y=ones(size(t)); y(t>=10)=1e35; y(t>=11)=NaN;
[~,mask,info]=prepare_task4_history(t,y,6,cfg);
assert(info.padded_tail_samples==sum(t>=11) && ~any(mask(cfg.time_s>=10)));
shortTime=t(t<11); shortY=ones(size(shortTime)); shortY(shortTime>=10)=1e35;
[~,mask,info]=prepare_task4_history(shortTime,shortY,6,cfg);
assert(info.padded_tail_samples>0 && any(mask) && ~any(mask(cfg.time_s>=10)));
y=y(1:find(t<11,1,'last'));
[~,mask,info]=prepare_task4_history(t,y,6,cfg);
assert(info.padded_tail_samples==sum(t>=11) && ~any(mask(cfg.time_s>=10)));
% Inadequate time coverage must fail, not extrapolate silently.
try
    prepare_task4_history(t(1:100),ones(100,1),6,cfg);
    error('Test:ExpectedFailure','Expected a coverage failure.');
catch err
    assert(strcmp(err.identifier,'Task4:InsufficientTimeCoverage'));
end
fprintf('Task 4 synthetic self-test passed.\n');
end
