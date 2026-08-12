function failure_data = build_failure_database(dataset, cfg)
%BUILD_FAILURE_DATABASE Response-specific onset results for all 70 cases.
onset_step = inf(cfg.num_realizations, cfg.num_points, cfg.num_responses);
onset_time_s = inf(size(onset_step)); onset_value = nan(size(onset_step));
detected = false(size(onset_step));
for p = 1:cfg.num_points
 for r = 1:cfg.num_responses
  for s = 1:cfg.num_realizations
   rows = dataset.sim_id == s;
   out = detect_instability_onset(dataset.Y(rows,p,r), dataset.time_s(rows), r, cfg.detector);
   onset_step(s,p,r)=out.onset_step; onset_time_s(s,p,r)=out.onset_time_s;
   onset_value(s,p,r)=out.onset_value; detected(s,p,r)=out.failure_detected;
  end
 end
end
failure_data = struct('schema_name','task2_failure_database', ...
 'created_utc',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX')), ...
 'detector_name','instability_onset','detector_parameters',cfg.detector, ...
 'response_specific',true,'onset_step',onset_step,'onset_time_s',onset_time_s, ...
 'onset_value',onset_value,'failure_detected',detected);
end
