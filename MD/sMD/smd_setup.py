#!/usr/bin/env python
# Alex Pérez-Sánchez, Jan 2024, MolBioMed (Univ. Autònoma de Barcelona)
# Setup for Steered Molecular Dynamics for Amber 
import argparse
import os
import mdtraj as md
import MDAnalysis as mda
import numpy as np


# Set default values for parameters
name_prm = "h_COX_2_dos_anells_5_cis_O_NH_CH3_solv.prmtop"
name_crd = "h_COX_2_dos_anells_5_cis_O_NH_CH3_solv.inpcrd"
num_steps = ""
atom_1 = ""
atom_2 = ""
dist_start = ""
dist_end = ""
cluster = "local"

# Parse command line options
parser = argparse.ArgumentParser(description="SMD Setup Tool by MolBioMed Research Group, Univ. Autònoma de Barcelona")
parser.add_argument("-p", dest="name_prm", required=True, help="Parameters file name.")
parser.add_argument("-c", dest="name_crd", required=True, help="Coordinates file name.")
parser.add_argument("-n", dest="num_steps", required=True, help="Number of trajectory steps.")
parser.add_argument("-a1", dest="atom_1", required=True, help="Atom 1 to perform the steered MD.")
parser.add_argument("-a2", dest="atom_2", required=True, help="Atom 2 to perform the steered MD.")
parser.add_argument("-d", dest="dist_end", help="Expected ending distance between atom 1 and 2.")
parser.add_argument("-q", dest="cluster", default="local", help="Name of the cluster. Options: [picard|csuc|local]. Default: local")
args = parser.parse_args()

# Assign parsed values to variables
name_prm = args.name_prm
name_crd = args.name_crd
num_steps = args.num_steps
atom_1 = args.atom_1
atom_2 = args.atom_2
dist_end = args.dist_end
cluster = args.cluster

# Check if required options are provided
if not all([name_prm, num_steps, atom_1, atom_2]):
    print("\nSMD Setup Tool by MolBioMed Research Group, Univ. Autònoma de Barcelona")
    print("\nUsage: python script.py -p <name_prm> -n <traj_steps> -a1 <atom_1> -a2 <atom_2>  -d <distance_end> [-q <cluster>]")
    print("Options:")
    print("  -p  <name_prm>       Parameters file name.")
    print("  -c  <name_crd>       Coordinates file name.")
    print("  -n  <traj_steps>     Numer of trajectory steps.")
    print("  -a1 <atom_1>         Atom 1 to perform the steered MD.")
    print("  -a2 <atom_2>         Atom 2 to perform the steered MD")
    print("  -d  <distance_end>   Expected ending distance between atom 1 and 2. ")
    print("  -q  <cluster>        Name of the cluster. Options: [picard|csuc|local]. Default: {}".format(cluster))
    exit(1)

## Slurm script generation for local, picard or slar
def generate_slurm_script(cluster):
    if cluster == 'local':
        sbatch_params = """#!/bin/bash
#SBATCH -J SMD
#SBATCH -e SMD_%j.err
#SBATCH -o SMD_%j.out
#SBATCH -p gpu
#SBATCH -n 1
#SBATCH -t 15-00:00
ml Amber/22
"""
    elif cluster == 'csuc':
        sbatch_params = """#!/bin/bash
#SBATCH -J SMD
#SBATCH -e SMD_%j.err
#SBATCH -o SMD_%j.out
#SBATCH -p gpu
#SBATCH -n 1
#SBATCH -t 15-00:00
"""
    elif cluster == 'slar':
        sbatch_params = """#!/bin/bash
#SBATCH -J SMD
#SBATCH -e SMD_%j.err
#SBATCH -o SMD_%j.out
#SBATCH -p gpu
#SBATCH -n 1
#SBATCH -t 15-00:00
"""
    else:
        print(f"Error: Unknown cluster '{cluster}'. Please provide a valid cluster.")
        return

    script = f"""{sbatch_params}
# Additional cluster-specific commands or configurations can be added here

# Your simulation command goes here
"""

    with open(f'smd_slurm_script_{cluster}.sh', 'w') as file:
        file.write(script)

# Example usages
generate_slurm_script('local')
generate_slurm_script('csuc')
generate_slurm_script('slar')


# Process all *.rst7 files in the current directory
for rst7_file in os.listdir("."):
    if rst7_file.endswith(".rst7") and os.path.isfile(rst7_file):
        # Extract the number from the rst7 file name
        number = int(rst7_file.split('_')[0])
        prmtop_file = name_prm # replace with your prmtop file
        inpcrd_file = name_crd  # replace with your inpcrd file
        rst_file = rst7_file  # replace with your restart file
        traj = md.load(inpcrd_file, top=prmtop_file)
        converted_traj_file = 'converted_traj.dcd'
        traj.save_dcd(converted_traj_file)
        u = mda.Universe(prmtop_file, converted_traj_file)
        atom1 = u.select_atoms(f'bynum {atom_1}')
        atom2 = u.select_atoms(f'bynum {atom_2}')
        dist_start = np.linalg.norm(atom1.positions[0] - atom2.positions[0])
        dist_end = dist_start + 10
        # Create input files
        with open(f"asmd_{number}.in", "w") as in_file:
            in_file.write(f"""ASMD simulation
 &cntrl
   imin = 0, nstlim = {num_steps}, dt = 0.002,
   ntx = 1, temp0 = 300.0,
   ntt = 3, gamma_ln=5.0
   ntc = 2, ntf = 2, ntb =1,
   ntwx =  1000, ntwr = {num_steps}, ntpr = 1000,
   cut = 8.0, ig=-1, ioutfm=1,
   irest = 0, jar=1, 
 /
 &wt type='DUMPFREQ', istep1=1000 /
 &wt type='END'   /
DISANG=dist.RST.dat.{number}
DUMPAVE=asmd_{number}.work.dat
LISTIN=POUT
LISTOUT=POUT
""")

        with open(f"dist.RST.dat.{number}", "w") as dist_file:
            dist_file.write(f""" &rst
        iat={atom_1},{atom_2},
        r2={dist_start},
        r2a={dist_end},
        rk2=7.2,
 &end
""")

        # Append Slurm script lines for each rst7 file
        with open(f'smd_slurm_script_{cluster}.sh', "a") as slurm_file:
            slurm_file.write(f"pmemd.cuda -O -i asmd_{number}.in -o asmd_{number}.out -p {name_prm} -c {rst7_file} -ref {rst7_file} -r asmd_{number}.rst -inf asmd_{number}.mdinfo -x asmd_{number}.nc\n")


print("Setup completed. Run the simulation using:")
print("./smd_slurm_script.sh")
