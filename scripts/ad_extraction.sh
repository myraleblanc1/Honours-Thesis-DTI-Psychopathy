#AD extraction script 

SUBJECT_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw'
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'

# Use the RESAMPLED ROI masks
UF_L="$ROI_DIR/UF_L.nii.gz"
UF_R="$ROI_DIR/UF_R.nii.gz"
DC_L="$ROI_DIR/DC_L.nii.gz"
DC_R="$ROI_DIR/DC_R.nii.gz"

OUTPUT='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed/roi_L1_values.csv'
echo "Subject,UF_L_L1,UF_R_L1,DC_L_L1,DC_R_L1" > $OUTPUT

for subj in $SUBJECT_DIR/*; do
    if [[ -d "$subj" ]]; then

        ID=$(basename "$subj")
        L1_IMAGE="$subj/rdti_L1_to_target.nii.gz"

        if [[ ! -f "$L1_IMAGE" ]]; then
            echo "Skipping $ID (no L1 image)"
            continue
        fi

        echo "Extracting L1 for $ID..."

        UF_L_L1=$(fslmeants -i $L1_IMAGE -m $UF_L)
        UF_R_L1=$(fslmeants -i $L1_IMAGE -m $UF_R)
        DC_L_L1=$(fslmeants -i $L1_IMAGE -m $DC_L)
        DC_R_L1=$(fslmeants -i $L1_IMAGE -m $DC_R)

        echo "$ID,$UF_L_L1,$UF_R_L1,$DC_L_L1,$DC_R_L1" >> $OUTPUT
    fi
done

echo "Saved AD ROI table to $OUTPUT"
