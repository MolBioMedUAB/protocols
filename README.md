# protocols

This repo contains a collection of protocols useful for carrying out different types of computational-chemistry simulations.

## MD (Molecular Dynamics)

### cMD (Conventional MD)

    - create_md.sh: Bash script for creating all files and folders required for carrying out conventional MD simulations, including the preproduction step. Further information can be found in the comments inside the script.

### aMD (Accelerated MD)

    - aMD_energy_reweighting.sh: Bash script that assists the energy rewighting of an aMD using the PyRewighting package from MiaoLab. Further information can be found in the script.

### GaMD (Gaussian accelerated MD)
    - GaMD_equilibration_nvt.mdin & GaMD_equilibration_npt_semiisotropic.mdin: AMBER inputs for running GaMD equilibration in NVT and semiisotropic NPT conditions.
    - GaMD_production_nvt.mdin & GaMD_production_npt_semiisotropic.mdin: AMBER inputs for running GaMD production in NVT and semiisotropic NPT conditions.
