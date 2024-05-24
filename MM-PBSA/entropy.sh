#!/bin/bash
## Alejandro Cruz & Álex Pérez-Sanchez, MolBioMed, Universitat Autònoma de Barcelona, 2023
## Setup and Calculation of entropy for MM-PBSA Binding Energies

# Check if the number of arguments is correct
if [ $# -ne 1 ]; then
    echo "Usage: $0 <num_frames>"
    exit 1
fi

# Number of frames provided as a command-line argument
num_frames=$1

# Extract the 3rd and 6th columns from each file

cat _MMPBSA_complex_pb.mdout.* | grep VDWAALS | awk '{print $3, $6}' > complex.dat
cat _MMPBSA_receptor_pb.mdout.* | grep VDWAALS | awk '{print $3, $6}' > receptor.dat
cat _MMPBSA_ligand_pb.mdout.* | grep VDWAALS | awk '{print $3, $6}' > ligand.dat


# Fortran code
cat <<EOF > calculation_entropy.f90
program main
implicit none
integer :: ii
real :: suma

call lectura (suma)

contains
        !Llegeix les dades necesàries per tal de fer els analisi corresponents!
        subroutine lectura (suma)

        implicit none
        real, dimension(:), allocatable :: vdw_c,eel_c,vdw_r,eel_r,vdw_l,eel_l,total
        real :: average, incr, kb, t, beta, suma
        integer :: ii

	allocate(vdw_c($num_frames),eel_c($num_frames),vdw_r($num_frames),eel_r($num_frames),vdw_l($num_frames),eel_l($num_frames))
        allocate(total($num_frames))

        open(unit=20, file='complex.dat',form='formatted',status='old')
        do ii=1, $num_frames
                read(20,*) vdw_c(ii),eel_c(ii)
        end do
        close(20)

        open(unit=20, file='receptor.dat',form='formatted',status='old')
        do ii=1, $num_frames
                read(20,*) vdw_r(ii),eel_r(ii)
        end do
        close(20)

        open(unit=20, file='ligand.dat',form='formatted',status='old')
        do ii=1, $num_frames
                read(20,*) vdw_l(ii),eel_l(ii)
        end do
        close(20)

        kb = 0.001987204
        beta = 1.677399
        t = 300

        average = 0
        do ii=1, $num_frames
                total(ii) = vdw_c(ii) + eel_c(ii) -vdw_r(ii) - eel_r(ii) - vdw_l(ii) - eel_l(ii)
                average = average + total(ii)
        end do

        average = average/$num_frames
        suma = 0
        do ii=1, $num_frames
                incr = total(ii) - average
                incr = incr * beta
                incr = exp(incr)
                suma = suma + incr
        end do

        suma = suma/$num_frames
        suma = kb*t*log(suma)
        suma = -suma/t
        print *, suma
        end subroutine

end program
EOF

# Compile and execute the Fortran program with the specified number of frames and output prefix
gfortran -o calculation_entropy calculation_entropy.f90
./calculation_entropy
