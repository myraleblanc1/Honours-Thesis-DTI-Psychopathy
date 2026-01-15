PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW_DIR="$PROJECT_ROOT/data/raw"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"
ORIGDATA_DIR="$TBSS_DIR/origdata"

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")

    RD="$subj/rdti_RD.nii.gz"
    L1="$subj/rdti_L1.nii.gz"
    MD="$subj/rdti_MD.nii.gz"

    if [[ -f "$RD" && -f "$L1" && -f "$MD" ]]; then
        cp "$RD" "$ORIGDATA_DIR/${ID}_RD.nii.gz"
        cp "$L1" "$ORIGDATA_DIR/${ID}_L1.nii.gz"
        cp "$MD" "$ORIGDATA_DIR/${ID}_MD.nii.gz"
    else
        echo "[WARNING] Missing RD/L1/MD for $ID"
    fi
done
