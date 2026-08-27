# Published Task 1 configuration

The paper began with 49 candidate random variables. One-at-a-time sensitivity
analysis used lower, baseline, and upper evaluations (99 numerical cases) and
a greater-than-1% response swing criterion, while retaining representation of
each material-property family. Eighteen variables were retained for Latin
hypercube sampling and 500 first-impoundment realizations.

Ten QoIs and four responses produced 40 scalar targets. Sample sizes of 50,
100, 150, 200, 300, 400, and 500 were assessed. The paper identified 200 as
adequate; the 70/30 split then contains 140 development and 60 testing cases.
Inputs and targets were mapped to `[-1,1]`; sigmoid activation and RMSE fitness
were used. The compared methods were ELM, ELM-ABC, ELM-ACOR, and ELM-IGWO.

FoS was modeled separately using the same 18 predictors and four methods.
