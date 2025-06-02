# protocols

This repo contains a collection of protocols useful for carrying out different types of computational-chemistry simulations.

## MD (Molecular Dynamics)

### cMD (Conventional MD)
- [create_md.sh](https://github.com/MolBioMedUAB/protocols/blob/main/MD/cMD/create_md.sh): Bash script for creating all files and folders required for carrying out conventional MD simulations, including the preproduction step. Further information can be found in the comments inside the script.

### aMD (Accelerated MD)
- [aMD_energy_reweighting.sh](https://github.com/MolBioMedUAB/protocols/blob/main/MD/aMD/aMD_energy_reweighting.sh): Bash script that assists the energy rewighting of an aMD using the PyRewighting package from MiaoLab. Further information can be found in the script.

### GaMD (Gaussian accelerated MD)
- [GaMD_equilibration_nvt.mdin](https://github.com/MolBioMedUAB/protocols/blob/main/MD/GaMD/GaMD_equilibration_nvt.mdin) & [GaMD_equilibration_npt_semiisotropic.mdin](https://github.com/MolBioMedUAB/protocols/blob/main/MD/GaMD/GaMD_equilibration_npt_semiisotropic.mdin): AMBER inputs for running GaMD equilibration in NVT and semiisotropic NPT conditions.
- [GaMD_production_nvt.mdin](https://github.com/MolBioMedUAB/protocols/blob/main/MD/GaMD/GaMD_production_nvt.mdin) & [GaMD_production_npt_semiisotropic.mdin](https://github.com/MolBioMedUAB/protocols/blob/main/MD/GaMD/GaMD_production_npt_semiisotropic.mdin): AMBER inputs for running GaMD production in NVT and semiisotropic NPT conditions.

### sMD (Steered MD)
- [smd_setup.py](https://github.com/MolBioMedUAB/protocols/blob/main/MD/sMD/smd_setup.py): Python script for setting up a sMD simulation.
- [pmf_from_smd.py](https://github.com/MolBioMedUAB/protocols/blob/main/MD/sMD/pmf_from_smd.py): Python script for calculating PMF from several sMD simulations.

## MM-PBSA - Molecular Mechanics Poisson-Boltzmann Surface Area [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.15576931.svg)](https://doi.org/10.5281/zenodo.15576931)
- [mmpbsa_setup.sh](https://github.com/MolBioMedUAB/protocols/blob/main/MM-PBSA/mmpbsa_setup.sh): Bash script for creation of topology files of complex, receptor and ligand (ante-MMPBSA), and calculation of PB Binding energies of a ligand bind inside a receptor.
- [entropy.sh](https://github.com/MolBioMedUAB/protocols/blob/main/MM-PBSA/entropy.sh): Bash script for calculation from MM-PBSA results entropy correction of the binding energy. 

