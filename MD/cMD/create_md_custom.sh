#!/bin/bash

### FLAGS PARSER ###
parameters=''
coordinates=''
temperature=300
last_residue=''
length=200
machine='slurm'
submit=0

print_usage() {
  printf "Usage: ...\n"
  printf '%b\n' "\e[1m\t -c COORDINATES:\tspecify .inpcrd file\e[0m"
  printf '%b\n' "\t -l LENGTH:\t\tspecify the length of the production (in integer ns) [\e[1m200\e[0m]"
  printf '%b\n' "\t -m MACHINE:\t\tspecify the type of machine to use [csuc|local|mirfak|slar|slar-gorn03|\e[1mSLURM\e[0m]"
  printf '%b\n' "\e[1m\t -p PARAMETERS:\t\tspecify .prmtop file\e[0m"
  printf '%b\n' "\e[1m\t -r LAST_RESIDUE:\tspecify the number of the last residue from the protein and substrate, optionally\e[0m"
  printf '%b\n' "\t -t TEMPERATURE:\tspecify temperature (in K) [\e[1m300\e[0m]"
  printf "\n"
  printf '%b\n' "\e[3mBold indicates manatory argument or default value\e[0m"
  printf '%b\n' "\e[3mslar-gorn03 machine uses AMBER18 instead of AMBER20\e[0m"
  printf "\n"
  printf '%b\n' "\e[2mExample:\e[0m"
  printf '%b\n' "\e[2m\t setup_md.sh -t 310 -p file.prmtop -c file.inpcrd -r 555\e[0m"
}

while getopts 'c:l:m:p:r:t:sh' flag; do
  case "${flag}" in
    c) coordinates="${OPTARG}" ;;
    l) length="${OPTARG}" ;;
    m) machine="${OPTARG}" ;;
    p) parameters="${OPTARG}" ;;
    r) last_residue="${OPTARG}" ;;
    t) temperature="${OPTARG}" ;;
    s) submit=1 ;;
    h)
       print_usage
       exit 1 ;;
    *)
       print_usage
       exit 1 ;;
  esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$coordinates" ]; then
    echo "Missing -c (coordinates)"
    exit 1
fi

if [[ "csuc local mirfak slar slar-gorn03 slurm" =~ (' '|^)$machine(' '|$) ]];
then 
    echo
else 
    echo "Selected machine ($machine) is not configured. Remember that names have to be input in lower case.\n
Please, use an available config or the default (general SLURM config)."
    exit 1
fi

if [ -z "$parameters" ]; then
    echo "Missing -p (parameters)"
    exit 1
fi

if [ -z "$last_residue" ]; then
    echo "Missing -r (last residue of protein)"
    exit 1
fi

if [ -z "$temperature" ]; then
    echo "Temperature set to 300 K"
fi


### CREATE SUBDIRS
mkdir -p preprod/out
mkdir -p prod/out

### CREATE PREPROD INPUTS
echo "minimization of solvent
 &cntrl
  imin = 1, maxcyc = 1000,
  ncyc = 500, ntx = 1,
  ntwe = 0, ntwr = 500, ntpr = 100,
  ntc = 2, 
  ntf = 2, ntb = 1, ntp = 0,
  cut = 10.0,
  ntr=1, restraintmask = ':1-${last_residue}',
  restraint_wt = 250.,
  ioutfm=1, ntxo=1,
 /" > preprod/1_min.in

echo "Heating from 100 K to ${temperature}
 &cntrl
  imin = 0, nstlim = 1000000, dt = 0.002,
  irest = 0, ntx = 1, ig = -1,
  tempi = 100.0, temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 10000, ntwe = 0, ntwr = 1000, ntpr = 1000,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3., ntb = 1, ntp = 0,
  nscm = 0,
  ntr=1, restraintmask=':1-${last_residue}', restraint_wt=100.0,
  nmropt=0,
  ioutfm=1, ntxo=1,
 /" > preprod/2_heat.in

echo "1 ns NPT for eq WAT box
 &cntrl
  imin = 0, nstlim = 500000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 1, barostat = 2,
  nscm = 0,
  ntr=1, restraintmask=':1-${last_residue}', restraint_wt=100.,
  ioutfm=1, ntxo=1,
 /" > preprod/3_npt.in

echo "1 ns NPT with weaker restraint of solute
 &cntrl
  imin = 0, nstlim = 500000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3,  gamma_ln=3.0, ntb = 2, ntp = 1,
  nscm = 0, barostat = 2,
  ntr=1, restraintmask=':1-${last_residue}', restraint_wt=10.,
  ioutfm=1, ntxo=1,
 /" > preprod/4_npt.in

echo "Minimization of everything excluding backbone
 &cntrl
  imin = 1, maxcyc = 1000,
  ncyc = 500, ntx = 1,
  ntwe = 0, ntwr = 500, ntpr = 100,
  ntc = 2, ntf = 2, ntb = 1, ntp = 0,
  cut = 8.0,
  ntr=1, restraintmask=\"@CA,N,C\", restraint_wt=10.,
  ioutfm=1, ntxo=1,
 /" > preprod/5_min.in

echo "1 ns NPT with weak restraint of backbone
  imin = 0, nstlim = 500000, dt = 0.002,
  irest = 0, ntx = 1, ig = -1,
  tempi = 310.15, temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 1,
  nscm = 0, barostat = 2,
  ntr=1, restraintmask=\"@CA,N,C\", restraint_wt=10.,
  ioutfm=1, ntxo=1,
 /" > preprod/6_npt.in

echo "1 ns NPT with weaker restraint of backbone
  imin = 0, nstlim = 500000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 1,
  nscm = 0, barostat = 2,
  ntr=1, restraintmask=\"@CA,N,C\", restraint_wt=1.,
  ioutfm=1, ntxo=1,
 /" > preprod/7_npt.in

echo "1 ns NPT with weakest restraint of backbone
  imin = 0, nstlim = 1000000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 1,
  nscm = 0, barostat = 2,
  ntr=1, restraintmask=\"@CA,N,C\", restraint_wt=0.1,
  ioutfm=1, ntxo=1,
 /" > preprod/8_npt.in

echo "&cntrl
  imin = 0, nstlim = 1000000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 500, ntpr = 500,
  cut = 8.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 1,
  nscm = 1000, barostat = 2,
  ioutfm=1, ntxo=1,
 /" > preprod/9_npt.in

echo "NVT equilibration. 5 ns MD
 &cntrl
  imin = 0, nstlim =2500000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 5000, ntpr = 5000,
  cut = 9.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 0,
  ioutfm=1, ntxo=1,
/" > preprod/10_nvt.in

## CREATE PROD
echo "NVT production. 10 ns MD per step
 &cntrl
  imin = 0, nstlim =5000000, dt = 0.002,
  irest = 0, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 5000, ntpr = 5000,
  cut = 9.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 0,
  ioutfm=1, ntxo=1,
/" > prod/prod_01.in

echo "NVT production. 10 ns MD per step
 &cntrl
  imin = 0, nstlim =5000000, dt = 0.002,
  irest = 1, ntx = 5, ig = -1,
  temp0 = ${temperature},
  ntc = 2, ntf = 2, tol = 0.00001,
  ntwx = 5000, ntwe = 0, ntwr = 5000, ntpr = 5000,
  cut = 9.0, iwrap = 1,
  ntt =3, gamma_ln=3.0, ntb = 2, ntp = 0,
  ioutfm=1, ntxo=1,
/" > prod/prod.in

## CREATE SCRIPT
steps=$(echo "($length + 9) / 10" | bc)
#rounds the expected length to the next 10ths so length >= the requested

if [[ $((steps*10)) -gt $length ]]
then
    echo "$((steps*10)) ns will be simulated instead of ${length} ns"
fi

### SAVE HEADER INTO script.sh
jobname=$(echo "${parameters%.*}")

if [ $machine == 'csuc' ]
then
    echo "#!/bin/bash

#SBATCH --job-name=$jobname
#SBATCH --partition=gpu
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH -t 10-00:00

### LOAD MODULE ###
module load amber/20
"

elif [ $machine == 'local' ]
then
    echo "#! /bin/bash
export CUDA_VISIBLE_DEVICES=0" > script.sh

elif [ $machine == 'mirfak' ]
then
    echo "#!/bin/bash

#SBATCH --job-name=$jobname
#SBATCH --partition=LocalQ
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1

### LOAD MODULE ###
module load amber/20
" > script.sh

elif [ $machine == 'slar' ]
then 
    echo "#!/bin/bash

#SBATCH --job-name=$jobname
#SBATCH --partition=gorn4
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1

### LOAD MODULE ###
module load gcc/4.8.5/openmpi/4.1.1/cuda/11.1.1/amber/20.gorn04
" > script.sh

elif [ $machine == 'slar-gorn03' ]
then 
    echo "#!/bin/bash

#SBATCH --job-name=$jobname
#SBATCH --partition=gorn3
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1

### LOAD MODULE ###
module load gcc/4.8.5/openmpi/2.0.1/cuda/8.0/amber/18
" > script.sh


elif [ $machine == 'slurm' ]
then 
    echo "#!/bin/bash

#SBATCH --job-name=$jobname
#SBATCH --partition=
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1

### LOAD MODULE ###
module load 
" > script.sh
fi



echo "# set VARS
## general
prmtop=${parameters}
inpcrd=${coordinates}

# preproduction
declare -i preprod=1

# production
prefix='prod'
declare -i copy_preprod=1
declare -i prod=1
declare -i cnt=1
declare -i cntmax=${steps}

if [ \$preprod -eq 1 ];
then
    cd preprod

    echo 'starting first minimisation (step 1)'
    pmemd -O -i 1_min.in\\
                -o out/1_min.out -p ../\$prmtop -c ../\$inpcrd -r out/1_min.rst\\
                -inf 1_min.info -ref ../\$inpcrd -x out/1_min.nc

    echo 'starting first heating (step 2)'
    pmemd.cuda -O -i 2_heat.in\\
                -o out/2_heat.out -p ../\$prmtop -c out/1_min.rst -r out/2_heat.rst\\
                -inf 2_heat.info -ref out/1_min.rst -x out/2_heat.nc

    echo 'starting first NPT \(step 3\)'
    pmemd.cuda -O -i 3_npt.in\\
                -o out/3_npt.out -p ../\$prmtop -c out/2_heat.rst -r out/3_npt.rst\\
                -inf out/3_npt.info -ref out/2_heat.rst -x out/3_npt.nc

    echo 'starting second NPT \(step 4\)'
    pmemd.cuda -O -i 4_npt.in\\
                -o out/4_npt.out -p ../\$prmtop -c out/3_npt.rst -r out/4_npt.rst\\
                -inf 4_npt.info -ref out/3_npt.rst -x out/4_npt.nc

    echo 'starting second minimisation \(step 5\)'
    pmemd -O -i 5_min.in\\
                -o out/5_min.out -p ../\$prmtop -c out/4_npt.rst -r out/5_min.rst\\
                -inf 5_min.info -ref out/4_npt.rst -x out/5_min.nc

    echo 'starting third NPT \(step 6\)'
    pmemd.cuda -O -i 6_npt.in\\
                -o out/6_npt.out -p ../\$prmtop -c out/5_min.rst -r out/6_npt.rst\\
                -inf 6_npt.info -ref out/5_min.rst -x out/6_npt.nc

    echo 'starting fourth NPT \(step 7\)'
    pmemd.cuda -O -i 7_npt.in\\
                -o out/7_npt.out -p ../\$prmtop -c out/6_npt.rst -r out/7_npt.rst\\
                -inf 7_npt.info -ref out/6_npt.rst -x out/7_npt.nc

    echo 'starting fifth NPT \(step 8\)'
    pmemd.cuda -O -i 8_npt.in\\
                -o out/8_npt.out -p ../\$prmtop -c out/7_npt.rst -r out/8_npt.rst\\
                -inf 8_npt.info -ref out/7_npt.rst -x out/8_npt.nc

    echo 'starting sixth NPT \(step 9\)'
    pmemd.cuda -O -i 9_npt.in\\
                -o out/9_npt.out -p ../\$prmtop -c out/8_npt.rst -r out/9_npt.rst\\
                -inf out/8_npt.info -ref out/8_npt.rst -x out/9_npt.nc

    echo 'starting NVT equilibration \(step 10\)'
    pmemd.cuda -O -i 10_nvt.in\\
                -o out/10_nvt.out -p ../\$prmtop -c out/9_npt.rst -r out/10_nvt.rst\\
                -inf out/10_nvt.info -ref out/9_npt.rst -x out/10_nvt.nc
fi

if [ \$prod -eq 1 ];
then
    cd prod
    if [ \$copy_preprod -eq 1 ]
    then
        cp ../preprod/10_nvt.rst .
    fi

    while [ \${cnt} -le \${cntmax} ]
    do
        pcnt=\$((\${cnt} - 1))

        istep=\${prefix}_\${cnt}
        pstep=\${prefix}_\${pcnt}

        if [ \${cnt} -eq 1 ]
        then
            pmemd.cuda -O -ref 10_nvt.rst -p ../\$prmtop -c 10_nvt.rst  -i \${istep}.in -o out/\${istep}.mdout -inf \${istep}.mdinf -r out/\${istep}.rst -x out/\${istep}.nc

        else
            pmemd.cuda -O -ref out/\${pstep}.rst -p ../\$prmtop -c out/\${pstep}.rst  -i \${prefix}.in -o out/\${istep}.mdout -inf \${istep}.mdinf -r out/\${istep}.rst -x out/\${istep}.nc
        fi

        cnt=\$((\$cnt + 1))
    done
fi
" >> script.sh

# SEND JOB
if [ $submit -eq 1 ]
then
    if [[ "csuc mirfak slar slar-gorn03" =~ (' '|^)$machine(' '|$) ]];
    then 
        sbatch script.sh
    fi
fi
