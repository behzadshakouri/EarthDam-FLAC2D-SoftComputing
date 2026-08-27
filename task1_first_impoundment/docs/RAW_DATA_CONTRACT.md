# Raw data contract

## `outputs_gp.mat`

Required variables:

- `RVs`: `500 x 18` finite double matrix;
- `outputs_gp`: `28392 x 6 x 500` finite double array.

The first array dimension is the FLAC2D grid row, the second contains source
columns, and the third is realization. Columns 3-6 are X displacement, Y
displacement, Sxx, and Syy. QoI rows are defined in
`config/task1_qoi_dictionary.m`.

## `PT1_FoS_SCT.xlsx`

The canonical range is `Sheet1!A1:S500`, without a header row:

- columns A-R: 18 uncertain inputs;
- column S: factor of safety.

Auxiliary content outside A1:S500 is ignored. Raw files remain outside Git and
are available from the corresponding author upon reasonable request.
