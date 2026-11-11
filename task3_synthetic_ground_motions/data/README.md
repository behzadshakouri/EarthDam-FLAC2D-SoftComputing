# Private Task 3 Data

Place no study MAT-files in version control. The expected private file is
`Task3Data.mat` (approximately 0.49 GB), containing 150 synthetic
ground-motion inputs and 70 sets of response histories.

Configure its location through an ignored file:

```matlab
% config/task3_local_paths.m
function paths = task3_local_paths(paths)
paths.task3_data_file = 'E:\path\to\Task3Data.mat';
end
```

The repository contains a synthetic smoke test, so the code can be checked
without access to the private database or FLAC2D.
