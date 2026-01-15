RAW_DIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw"

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")

    RD="$subj/rdti_RD.nii.gz"
    L1="$subj/rdti_L1.nii.gz"
    MD="$subj/rdti_MD.nii.gz"

    if [[ -f "$RD" && -f "$L1" && -f "$MD" ]]; then
        cp "$RD" "origdata/${ID}_RD.nii.gz"
        cp "$L1" "origdata/${ID}_L1.nii.gz"
        cp "$MD" "origdata/${ID}_MD.nii.gz"
    else
        echo "[WARNING] Missing RD/L1/MD for $ID"
    fi
done
