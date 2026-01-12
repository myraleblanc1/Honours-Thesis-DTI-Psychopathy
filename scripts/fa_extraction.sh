#fa extraction script 

SUBJECT_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw'
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'

# Use the RESAMPLED ROI masks
UF_L="$ROI_DIR/UF_L_resampled.nii.gz"
UF_R="$ROI_DIR/UF_R_resampled.nii.gz"
DC_L="$ROI_DIR/DC_L_resampled.nii.gz"
DC_R="$ROI_DIR/DC_R_resampled.nii.gz"

OUTPUT='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed/roi_FA_values.csv'
echo "Subject,UF_L_FA,UF_R_FA,DC_L_FA,DC_R_FA" > $OUTPUT

for subj in $SUBJECT_DIR/*; do
    if [[ -d "$subj" ]]; then

        ID=$(basename "$subj")
        FA_IMAGE="$subj/tbdti_FA.nii.gz"

        if [[ ! -f "$FA_IMAGE" ]]; then
            echo "Skipping $ID (no FA image)"
            continue
        fi

        echo "Extracting FA for $ID..."

        UF_L_FA=$(fslmeants -i $FA_IMAGE -m $UF_L)
        UF_R_FA=$(fslmeants -i $FA_IMAGE -m $UF_R)
        DC_L_FA=$(fslmeants -i $FA_IMAGE -m $DC_L)
        DC_R_FA=$(fslmeants -i $FA_IMAGE -m $DC_R)

        echo "$ID,$UF_L_FA,$UF_R_FA,$DC_L_FA,$DC_R_FA" >> $OUTPUT
    fi
done

echo "Saved FA ROI table to $OUTPUT"
