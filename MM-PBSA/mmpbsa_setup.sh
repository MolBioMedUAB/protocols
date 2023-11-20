#!/bin/bash
# Alex Pérez-Sánchez, Oct 2023, MolBioMed (Univ. Autònoma de Barcel)
# Setup for MMPBSA Calculations 

# Default values for options
job_name="MMPBSA_job"
input_traj="trajectory.nc"
frames="5000"
input_prmtop="system.prmtop"
input_crd="input.crd"
solvent_mask=":WAT:Na+:Cl-"
ligand_mask=":LIG"
cluster="local"
output_prefix="mmpbsa_output"
pb_radius="mbondi2"


# Function to display the script's usage information
show_help() {
    echo ""
    echo "MM-PBSA SETUP TOOL by MolBioMed Research Group, Univ. Autònoma de Barcelona"
    echo ""
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -j <job_name>       Job name. Default $job_name"
    echo "  -t <trajectory>     Path to the MD trajectory file. Default: $input_traj"
    echo "  -f <frames>         Number of frames of the previous MD trajectory. Default: $frames"
    echo "  -p <prmtop>         Path to the Amber topology file Default: $input_prmtop"
    echo "  -s <strip_mask>     Mask for selecting atoms of the solvent and ions. Default: $solvent_mask"
    echo "  -n <ligand>         Mask of the ligand (residue number). Default: $ligand_mask"
    echo "  -o <output_prefix>  Prefix for the output files Default: $output_prefix"
    echo "  -r <pb_radius>      PB/GB radius Default: $pb_radius"
    echo "  -q <cluster>        Name of the cluster. Options: [picard|csuc|local]. Default: $cluster"
    echo "  -h                  Display this help message"
    echo ""
    exit 1
}

# Parse command-line options
while getopts "j:t:f:p:c:s:n:o:r:q:h" opt; do
    case $opt in
        j)
            job_name="$OPTARG"
            ;;
        t)
            input_traj="$OPTARG"
            ;;
        f)
            frames="$OPTARG"
            ;;
        p)
            input_prmtop="$OPTARG"
            ;;

        s)
            solvent_mask="$OPTARG"
            ;;
        n)
            ligand_mask="$OPTARG"
            ;;
        o)
            output_prefix="$OPTARG"
            ;;
        r)
            pb_radius="$OPTARG"
            ;;
        q)
            cluster="$OPTARG"
            ;;
        h)
            show_help
            ;;
    esac
done

if [ -z "$job_name" ]; then
    echo "Job name set to $job_name."
fi

if [ -z "$output_prefix" ]; then
    echo "Output prefix set to $output_prefix."
fi

if [ -z "$input_traj" ]; then
    echo "Missing -t (trajectory input file)"
    exit 1
fi

if [ -z "$input_prmtop" ]; then
    echo "Missing -p (parameters)"
    exit 1
fi

if [ -z "$solvent_mask" ]; then
    echo "Missing -s (Solvent stripping mask)"
    exit 1
fi

if [ -z "$ligand_mask" ]; then
    echo "Missing -l (Ligand stripping mask)"
    exit 1
fi

if [[ "picard csuc local" =~ (' '|^)$cluster(' '|$) ]];
then
    echo
else
    echo "Selected machine ($cluster) is not configured. Remember that names have to be input in lower case.\n
Please, use an available config or the default (general SLURM config)."
    exit 1
fi



# Create an MMPBSA input file (mmpbsa.in)
echo "Input file for MMPBSA calculations
&general
   startframe=1, endframe=$frames, keep_files=2, netcdf=1, interval=5,
/
&pb
   istrng=0.100,
" > mmpbsa.in


### SAVE HEADER INTO script.sh
jobname=$(echo "${input_prmtop%.*}")

if [ "$cluster" == "picard" ]
then
    echo "#!/bin/bash
#SBATCH -J "$job_name"
#SBATCH -e "$job_name"_%j.err
#SBATCH -o "$job_name"_%j.err
#SBATCH -p normal
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -t 15-00:00
ml Amber/20.11-foss-2020b-AmberTools-21.3
cp -r * \$TMP_DIR
cd \$TMP_DIR
ante-MMPBSA.py -p "$input_prmtop" -c complex.prmtop -r receptor.prmtop -l ligand.prmtop -s "$solvent_mask" -n "$ligand_mask" --radii="$pb_radius"
MMPBSA.py -O -i mmpbsa.in -o mmpbsa_"$job_name".dat -sp "$input_prmtop" -cp complex.prmtop -rp receptor.prmtop -lp ligand.prmtop -y "$input_traj" 
cp * \$SLURM_SUBMIT_DIR
date
" > script_mmpbsa.sh

elif [ "$cluster" == 'csuc' ]
then
    echo "#!/bin/bash
#SBATCH -J $job_name
#SBATCH -e $job_name_%j.err
#SBATCH -o $job_name_%j.err
#SBATCH -p gpu
#SBATCH -n 1
#SBATCH -t 15-00:00
module load apps/amber/20
cp -r * \$TMP_DIR
cd \$TMP_DIR
ante-MMPBSA.py -p $input_prmtop -c complex.prmtop -r receptor.prmtop -l ligand.prmtop -s $solvent_mask -n $ligand_mask --radii=$pb_radius
MMPBSA.py -O -i mmpbsa.in -o mmpbsa_$job_name.dat -sp $input_prmtop -cp complex.prmtop -rp receptor.prmtop -lp ligand.prmtop -y $input_traj 
" > script_mmpbsa.sh

elif [ "$cluster" == 'local' ]
then
    echo "#!/bin/bash
#SBATCH -J $job_name
#SBATCH -e $job_name_%j.err
#SBATCH -o $job_name_%j.err
#SBATCH -p cpu
#SBATCH -n 1
#SBATCH -t 15-00:00
ml Amber/22
ante-MMPBSA.py -p $input_prmtop -c complex.prmtop -r receptor.prmtop -l ligand.prmtop -s $solvent_mask -n $ligand_mask --radii=$pb_radius
MMPBSA.py -O -i mmpbsa.in -o mmpbsa_$job_name.dat -sp $input_prmtop -cp complex.prmtop -rp receptor.prmtop -lp ligand.prmtop -y $input_traj 
" > script_mmpbsa.sh
fi

chmod +x script_mmpbsa.sh



