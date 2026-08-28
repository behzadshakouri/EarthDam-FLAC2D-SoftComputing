# Third-party notices

## ELM method lineage

The historical Task 1 workflow instantiated the `ELM` class from the LabCISNE
ELMToolbox: https://github.com/labcisne/ELMToolbox. The canonical workflow uses
a project-local functional implementation and does not redistribute that class.

Foundational reference: G.-B. Huang, Q.-Y. Zhu, and C.-K. Siew, "Extreme
learning machine: Theory and applications," *Neurocomputing*, 70, 489-501,
2006. https://doi.org/10.1016/j.neucom.2005.12.126

## YPEA: Yarpiz Evolutionary Algorithms

- Source: https://github.com/smkalami/ypea
- Pinned commit: `192a610fdb67f0bdfb8a779a21bb765d9cfaeadb`
- Copyright: 2019 Yarpiz / Mostapha Kalami Heris
- License: MIT

The bundled source supplies the original ABC and ACOR implementations. Its
license is retained at `third_party/ypea/LICENSE`.

## Improved Grey Wolf Optimizer

- Source: https://www.mathworks.com/matlabcentral/fileexchange/81253-improved-grey-wolf-optimizer-i-gwo
- Version: 1.0
- Authors: M. H. Nadimi-Shahraki, S. Taghian, and S. Mirjalili
- License: BSD-style three-clause redistribution license

The original license is retained at `third_party/igwo/LICENSE`.

MATLAB, its toolboxes, and FLAC2D are proprietary products and are not
distributed with this repository. I-GWO uses `pdist`, `pdist2`, and
`squareform` from Statistics and Machine Learning Toolbox.
