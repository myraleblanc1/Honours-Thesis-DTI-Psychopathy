PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
ORIGDATA="$PROJECT_ROOT/TBSS_GROUP/origdata"

cd "$ORIGDATA"

for fa in *_FA.nii.gz; do
    base=$(basename "$fa" .nii.gz)

    subj=${base%_FA}

    RD="${subj}_RD.nii.gz"
    L1="${subj}_L1.nii.gz"
    MD="${subj}_MD.nii.gz"

    if [[ -f "$RD" && -f "$L1" && -f "$MD" ]]; then
        mv "$RD" "${base}_RD.nii.gz"
        mv "$L1" "${base}_L1.nii.gz"
        mv "$MD" "${base}_MD.nii.gz"
    else
        echo "[WARNING] Missing RD/L1/MD for $subj"
    fi
done
