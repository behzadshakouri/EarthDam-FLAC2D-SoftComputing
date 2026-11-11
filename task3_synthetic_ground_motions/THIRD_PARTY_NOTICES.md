# Third-Party Notices

## Fast Multi-Output Relevance Vector Regression

Files:

- `third_party/fmrvr_ha/fmrvr.m`
- `third_party/fmrvr_ha/license.txt`

Copyright (c) 2017, Youngmin Ha. These original files are redistributed under
the BSD-style terms reproduced in `license.txt`. Task 3 preprocessing,
selection, prediction, and evaluation wrappers are separate project files.

Reference: Ha, Y., and Zhang, H. (2019), “Fast multi-output relevance vector
regression,” *Economic Modelling*, 81, 217--230.
https://doi.org/10.1016/j.econmod.2019.04.007
## Local solver adaptation

`src/modeling/fmrvr_task3.m` derives from the included Youngmin Ha solver and
retains its BSD terms in `third_party/fmrvr_ha/license.txt`. It initializes
empty-model coefficient outputs before the EM loop; the original source is
preserved. Output-subspace preprocessing lives in the project wrapper.
