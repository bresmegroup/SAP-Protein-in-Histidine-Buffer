echo "Beginning generating frames"
./gen-frame.sh  # Generate frames (.gro files) from a trajectory file. The .gro files will be used for sasa calculation and neighbor list generation. 
echo "All frames generated"

echo "Modifying frame.gro files"
./sed.sh # Modify the .gro files by deleting the headers and footers to generate input for sap.f

echo "Generating framewise file names"
./input-filename.sh # Generate files with a list of filenames used for framewise input/output.

echo "Generating atomwise file names"
./output-filename.sh # Generate files with a list of filenames used for atomwise input/output.

echo "Generating neighbour list"
gfortran sap.f # Generate a framewise list of atoms within cutoff of each atom.
./a.out

./lines.sh # Count the number of lines in each output file from sap.f.

echo "Generating index files"
gfortran gen-index.f # Generate framewise index files for SASA calculation.
./a.out

./lines-tracefile.sh # Number of lines in the files generated for tracing the sasa output based on 

echo "Generating SASA input files"
gfortran gen-sasa-input.f #generate input file to pipe in to gmx sasa for each frame
./a.out

echo "Modifying index files"
./cat-index.sh # Modify the index files generated by gen-index.f by adding the Fab/Fc+Histidine buffer domain atom indices in a group at the top. (Needs a file called common.ndx with the atom indices of all the protein atoms Fab/Fc+Histidine buffer)

#./gen-frame.sh # Generate frames again as gmx sasa needs unedited .gro files. Not needed anymore. sed.sh and sasa.sh have been appropriately modified for this purpose.
./sasa.sh # Script file calculates SASA for each frame 

echo "Modifying SASA output files"
./sed-sasa.sh # Modify the SASA outputs to make the format uniform to be read by the fortran codes to follow

echo "Seggregating data framewise"
gfortran seggregate-framewise.f -mcmodel=medium # Add the SASA data to the tracefiles
./a.out

echo "Seggregating data atomwise"
gfortran seggregate-atomwise-2.f # Seggregate the information in the tracefile by atom index
./a.out

./lines-atomsfile.sh # Calculate the number of lines in the output generated by seggregate-atomwise.f

echo "Adding hydrophobicity, free SASA and residue information to output files"
gfortran modify-atomfiles.f #Generate files for each atom containing all data needed for SAP calculation. A file named hydrophobicity.dat needed as an input. This is a 3-column file containing residue_name, hydrophobicity (Black and Mould) and the sasa (Ala-X-Ala) trimer as the three columns.
./a.out

gfortran sequence.f #Generates a file called ressize.dat with the columns : resid, resname and residue atom count
./a.out
echo "Residuewise atom count generated"

gfortran sap-residuewise.f #Generates residuewsise SAP (The final output to be used for coloring)
./a.out

echo "Residue wise SAP calculated"
echo "DONE!!! Phewww..."
