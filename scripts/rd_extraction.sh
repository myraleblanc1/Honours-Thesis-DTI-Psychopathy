#rd extraction script 

SUBJECT_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw'
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'

# ROI masks
UF_L="$ROI_DIR/UF_L.nii.gz"
UF_R="$ROI_DIR/UF_R.nii.gz"
DC_L="$ROI_DIR/DC_L.nii.gz"
DC_R="$ROI_DIR/DC_R.nii.gz"

OUTPUT='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed/roi_RD_values.csv'
echo "Subject,UF_L_RD,UF_R_RD,DC_L_RD,DC_R_RD" > $OUTPUT

for subj in $SUBJECT_DIR/*; do
    if [[ -d "$subj" ]]; then

        ID=$(basename "$subj")
        RD_IMAGE="$subj/rdti_RD_to_target.nii.gz"

        if [[ ! -f "$RD_IMAGE" ]]; then
            echo "Skipping $ID (no RD image)"
            continue
        fi

        echo "Extracting RD for $ID..."

        UF_L_RD=$(fslmeants -i $RD_IMAGE -m $UF_L)
        UF_R_RD=$(fslmeants -i $RD_IMAGE -m $UF_R)
        DC_L_RD=$(fslmeants -i $RD_IMAGE -m $DC_L)
        DC_R_RD=$(fslmeants -i $RD_IMAGE -m $DC_R)

        echo "$ID,$UF_L_RD,$UF_R_RD,$DC_L_RD,$DC_R_RD" >> $OUTPUT
    fi
done

echo "Saved RD ROI table to $OUTPUT"
