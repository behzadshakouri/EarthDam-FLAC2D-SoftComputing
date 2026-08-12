# Third-party notices

## ELM method lineage

The authors' original FULL70 MATLAB workflow instantiated the `ELM` class
from the [LabCISNE ELMToolbox](https://github.com/labcisne/ELMToolbox),
inspected at commit `d266aa933772471353f678d8293ff7b327c9e35c`.

The canonical workflow uses a project-local functional implementation and
does not redistribute or require the LabCISNE class. LabCISNE is credited
because its architecture and property conventions formed the base of the
original workflow. The repository-level LabCISNE license and the notice
embedded in `ELMs/ELM.m` are not identical; avoiding redistribution of that
file prevents the project license from obscuring its original terms.

Foundational reference: G.-B. Huang, Q.-Y. Zhu, and C.-K. Siew, "Extreme
learning machine: Theory and applications," *Neurocomputing*, 70, 489-501,
2006. https://doi.org/10.1016/j.neucom.2005.12.126

## YPEA: Yarpiz Evolutionary Algorithms

- Source: https://github.com/smkalami/ypea
- Pinned commit: `192a610fdb67f0bdfb8a779a21bb765d9cfaeadb`
- Copyright: 2019 Yarpiz / Mostapha Kalami Heris
- License: MIT

The bundled `third_party/ypea/src/ypea` tree supplies the original
`ypea_abc` and `ypea_acor` implementations plus their required base classes
and utilities. The original license is retained at
`third_party/ypea/LICENSE`.

## Improved Grey Wolf Optimizer (I-GWO)

- Official source: https://www.mathworks.com/matlabcentral/fileexchange/81253-improved-grey-wolf-optimizer-i-gwo
- Version: 1.0
- Authors: M. H. Nadimi-Shahraki, S. Taghian, and S. Mirjalili
- License: BSD-style three-clause redistribution license

The original license is retained at `third_party/igwo/LICENSE`. The production
adapter preserves the supplied optimizer while using the project's objective,
bounds, seed, and ELM ridge-output solution.

Reference: M. H. Nadimi-Shahraki, S. Taghian, and S. Mirjalili, "An Improved
Grey Wolf Optimizer for Solving Engineering Problems," *Expert Systems with
Applications*, 166, 113917, 2021.
https://doi.org/10.1016/j.eswa.2020.113917

## MATLAB

MATLAB and its toolboxes are proprietary MathWorks products and are not
distributed with this repository. I-GWO uses `pdist`, `pdist2`, and
`squareform` from Statistics and Machine Learning Toolbox.
