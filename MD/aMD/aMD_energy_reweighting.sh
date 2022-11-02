# /bin/bash


##############################################
# PROTOCOL FOR REWEIGHTING ENERGY IN aMD AND #
#  PLOT AS HEATMAP CONFRONTING PC1 AND PC2   #
##############################################


PYREWEIGHT_HOME=
# $1 is topology (prmtop)
# $2 is reference frame (initial inpcrd)
# $3 is last residue number of protein
# $4 is trajectory files

# CREATE CPPTRAJ SCRIPT WITH GIVEN VARIABLES
vecs=$(($3*3))

echo "parm $1
trajin "$4"
reference $2

center origin :1-$3
image origin center

rms reference mass :1-$3@CA,C,N out ./RMSD.out
matrix covar name matrixdat @CA out covmat-ca.dat

diagmatrix matrixdat out ./evecs-ca.dat vecs $vecs
diagmatrix matrixdat name evecs-ca vecs $vecs

modes fluct out ./analyzemodesflu.dat name evecs-ca beg 1 end $vecs
modes displ out ./analyzemodesdis.dat name evecs-ca beg 1 end $vecs

go

projection modes evecs-ca.dat out pca12-ca beg 1 end 2 @CA

go""" > pcas_cpptraj.in

# STEP 1: RUN CPPTRAJ SCRIPT
echo "1. Run pcas_cpptraj.in with the following syntax:
\tFor serial run:   \tcpptraj -f pcas_cpptraj.in
\tFor parallel run: \tmpirun -np $procs cpptraj.MPI -i pcas_cpptraj.in
This run will take time depending on the lenght of the trajectory.
Steps 2 and 3 will be automatically done."

# STEP 2: MODIFY CPPTRAJ OUTPUT
#echo "2. Modify pca12-ca to remove header and first column (which contains the frame number). It will be done automatically."

awk '(NR>1)' pca12-ca > pca12-ca.tmp
awk '{ print $2, $3 }'  pca12-ca.tmp > pca12-ca.reduced
rm pca12-ca.tmp

# STEP 3: GENERATE weights.dat FOR PyReweight
awk 'NR%1==0' amd.log | awk '{print ($8+$7)/(0.001987*300)" " $2 " " ($8+$7)}' > weights.dat

# STEP 4: RUN PyReweighting-2D.py
python $PYREWEIGHT_HOME/PyReweighting-2D.py -cutoff 10 -input pca12-ca.reduced -T 310 -job amdweight_CE -weight weights.dat -cutoff 1 | tee -a reweight_variable.log

# STEP 5: PLOT HEATMAPS
echo "import numpy as np
import pandas as pd
import matplotlib.pyplot as plt"  > plot_heatmaps.py

echo "def load_xvg(filename):
    """
    Function for parsing the contents of a xvg file produced by PyReweighting
    """
    
    xvg = open(filename, 'r').readlines()
    
    labels = {
        'x' : xvg[0][1:].split('\t')[0],
        'y' : xvg[0][1:].split('\t')[1],
        'z' : xvg[0][1:].split('\t')[2][:-1],
    }
    
    data = []
    for l in xvg[6:]:
        data.append(l.split())
        
    return np.array(data, dtype=float), labels" >> plot_heatmaps.py

echo "def treat_xvg(data, labels):
    df = pd.DataFrame(data, columns=list(labels.values()))
    
    Z = df.pivot_table(index=labels['x'], columns=labels['y'], values=labels['z'], fill_value=0).T.values
    
    X_unique = np.sort(df.RC1.unique())
    Y_unique = np.sort(df.RC2.unique())
    X, Y = np.meshgrid(X_unique, Y_unique)

    return X, Y, Z" >> plot_heatmaps.py
    

echo "# CE1
data, labels = load_xvg('pmf-c1-pca12-cai.reduced.xvg')
X, Y, Z = treat_xvg(data, labels)

plt.contourf(X, Y, Z, levels=100, cmap='rainbow')
plt.colorbar()
plt.contour(X, Y, Z, levels=10, cmap='rainbow_r')

plt.show()
plt.close()" >> plot_heatmaps.py

echo "# CE2
data, labels = load_xvg('pmf-c2-pca12-ca.reduced.xvg')
X, Y, Z = treat_xvg(data, labels)

plt.contourf(X, Y, Z, levels=100, cmap='rainbow')
plt.colorbar()
plt.contour(X, Y, Z, levels=20, cmap='rainbow_r')

plt.show()
plt.close()" >> plot_heatmaps.py

echo "# CE3
data, labels = load_xvg('pmf-c3-pca12-ca_pc1_pc2_simple.xvg')
X, Y, Z = treat_xvg(data, labels)

plt.contourf(X, Y, Z, levels=100, cmap='rainbow')
plt.colorbar()
plt.contour(X, Y, Z, levels=20, cmap='rainbow_r')

plt.show()
plt.close()" >> plot_heatmaps.py

python plot_heatmaps.py


