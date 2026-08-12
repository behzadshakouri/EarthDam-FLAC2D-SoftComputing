# Repository context

Task 2 is distributed inside the `EarthDam-FLAC2D-SoftComputing` research
repository. It remains self-contained so its tagged paper release can be
reproduced independently of later tasks.

The separate `Dam_Model_FLAC2D_Runner` repository provides reusable FLAC2D
execution automation. It is not vendored here and is not required by the
post-processing workflow once the documented Task 2 inputs exist.

Future shared code should move to the umbrella `common/` directory only after
at least two tasks use it and compatibility with archived results is tested.
