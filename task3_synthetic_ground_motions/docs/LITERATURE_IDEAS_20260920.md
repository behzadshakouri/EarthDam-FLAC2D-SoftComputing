# Literature ideas for Task 3

The supplied Google Scholar profile belongs to Mohammad Amin
Hariri-Ardebili. Google Scholar itself returned a rate-limit response, so the
publication identity and paper list were cross-checked against the University
of Colorado publication page and the publishers' records.

## Closest studies

1. Hariri-Ardebili, Chen, and Mahdavi (2022), *Machine learning-aided PSDM
   for dams with stochastic ground motions*, Advanced Engineering
   Informatics 52, 101615.
   https://doi.org/10.1016/j.aei.2022.101615

   The study combines about 600 real and stochastic records, a three-dimensional
   concrete arch-dam model, five machine-learning methods, and IM--EDP/fragility
   comparisons. Its central warning is directly relevant: stochastic motions
   can support response prediction, but their feature coverage does not fully
   reproduce real-record variability.

2. Hariri-Ardebili and Barak (2020), *A series of forecasting models for
   seismic evaluation of dams based on ground motion meta-features*,
   Engineering Structures 203, 109657.
   https://doi.org/10.1016/j.engstruct.2019.109657

   About 2,000 real records and roughly 35 time-, frequency-, and
   intensity-dependent meta-features were used. The transferable idea is to
   screen compact feature groups and report their incremental value rather
   than assuming that a larger feature inventory is better.

3. Hariri-Ardebili and Pourkamali-Anaraki (2022), *An Automated Machine
   Learning Engine with Inverse Analysis for Seismic Design of Dams*, Water
   14, 3898. https://doi.org/10.3390/w14233898

   The database contains about 24,000 simulations, 160 ground motions, 15
   seismic descriptors, and geometric/material variables. It compares single-
   and multi-output surrogates. The useful idea for Task 3 is structured
   multi-output prediction, while the much larger database explains why its
   model complexity is not directly transferable to the present 150 cases.

## Implications for the present analysis

- The active spectral FMRVR input has 16 predictors: PGA, PGV, PGD, Arias
  intensity, CAV, D5--95 duration, acceleration RMS, mean frequency,
  predominant period, total record duration, and 5%-damped pseudo-spectral
  acceleration at 0.1, 0.2, 0.5, 1.0, 2.0, and 3.0 s.
- Dense spectra, Fourier bands, time-window features, modal-period features,
  and polynomial expansions have already been tested and did not improve the
  compact representation under development-only selection.
- The best validated design remains the multiscale rank-5 FMRVR with a soft
  stable/failed gate. Its ten-split mean R2 is 0.674.
- A nested severity-aware and family-specific refinement produced no material
  gain: mean R2 0.6743 versus 0.6743 for the matched baseline, with five wins
  in ten splits. It is rejected as a proposed model.
- The most defensible next accuracy improvement is additional simulations,
  preferentially sampled near the current instability boundary and in sparse
  regions of the 16-feature space. Repeatedly expanding the feature set on the
  same 150 cases is unlikely to supply independent information.
- If real records become available, evaluate synthetic-to-real transfer with
  parent/source groups kept entirely outside training folds. Do not randomly
  split scaled or related motions across training and testing.
