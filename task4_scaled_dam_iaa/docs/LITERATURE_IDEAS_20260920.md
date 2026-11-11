# Literature ideas for Task 4

## Closest studies

1. Hariri-Ardebili et al. (2025), *Bridging IAA and IDA: A conceptual
   framework, application, and implication in risk assessment*, International
   Journal of Disaster Risk Reduction 116, 105005.
   https://doi.org/10.1016/j.ijdrr.2024.105005

   This is the closest methodological reference. It compares a
   ground-motion-compatible intensifying artificial acceleration (IAA) with
   single-record IDA for a coupled concrete dam--water--foundation system. It
   evaluates local and global responses, deconvolution, crack-extension damage,
   collapse criteria, and conversion from IAA time to intensity measure.

2. Hariri-Ardebili and Nuss (2026), *Seismic Design of Concrete Dams: An
   Integrated Risk-Informed Performance-Based Framework*, Earthquake
   Engineering & Structural Dynamics 55, 1019--1049.
   https://doi.org/10.1002/eqe.70123

   Its 2D IAA sensitivity example varies elastic modulus and damping and
   post-processes two tensile strengths. It summarizes local demand--capacity
   ratio and the fraction of the dam exceeding tensile capacity, providing a
   useful pattern for Task 4 tables and figures.

3. Hariri-Ardebili and Mirzabozorg (2014), *Estimation of probable damages in
   arch dams subjected to strong ground motions using endurance time
   acceleration functions*, KSCE Journal of Civil Engineering 18, 574--586.
   https://doi.org/10.1007/s12205-013-0264-6

   This earlier dam application supports extracting damage/performance
   trajectories from an intensifying excitation rather than reporting only a
   terminal maximum.

## Recommended Task 4 analysis

- Convert every response history from time coordinates to intensity
  coordinates. Compare zero-period acceleration, Sa(T1), and mean spectral
  acceleration over 0.2--2.0 T1. The 2025 study found the band-averaged measure
  produced the smoothest capacity curve and reduced failure-intensity error.
- Treat numerical nonconvergence or the FLAC sentinel as one failure signal,
  not the physical limit state by itself. Pair it with engineering thresholds
  such as displacement/drift, stress-to-strength demand ratio, or a spatial
  damage fraction.
- Report both local and global measures: critical-point demand--capacity ratio,
  crest or relative displacement, and fraction of monitored locations above a
  specified limit.
- Preserve the full progressive capacity curve and extract curve descriptors:
  elastic slope, first threshold crossing, change point, peak demand, failure
  intensity, and post-threshold slope. These are stronger Task 4 prediction
  targets than a terminal response alone.
- If the foundation is modeled with mass and the input is defined at bedrock,
  verify the deconvolution convention before comparing IAA intensity with
  surface-motion IMs.
- Do not claim record-to-record fragility dispersion from one IAA. Multiple
  ground-motion-compatible IAAs are needed to represent aleatory variability;
  material/model samples add epistemic variability separately.
- For FMRVR, predict a low-rank representation of the response-versus-intensity
  curves and the physically defined threshold intensities. Keep complete IAA
  realizations together in all validation splits.
