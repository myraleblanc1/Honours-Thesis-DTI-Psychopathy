cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/TBSS_GROUP
mkdir -p RD L1 MD
ORIGDATA="$PWD/origdata"

for fa in "$ORIGDATA"/*_FA.nii.gz; do
    base=$(basename "$fa" .nii.gz)   # e.g. M87192571_FA
    subj=${base%_FA}                 # e.g. M87192571

    cp "$ORIGDATA/${subj}_RD.nii.gz" "RD/${base}.nii.gz"
    cp "$ORIGDATA/${subj}_L1.nii.gz" "L1/${base}.nii.gz"
    cp "$ORIGDATA/${subj}_MD.nii.gz" "MD/${base}.nii.gz"
done
