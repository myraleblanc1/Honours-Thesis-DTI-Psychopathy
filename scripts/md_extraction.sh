#MD extraction script 

SUBJECT_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw'
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'

# Use the RESAMPLED ROI masks
UF_L="$ROI_DIR/UF_L_resampled.nii.gz"
UF_R="$ROI_DIR/UF_R_resampled.nii.gz"
DC_L="$ROI_DIR/DC_L_resampled.nii.gz"
DC_R="$ROI_DIR/DC_R_resampled.nii.gz"

OUTPUT='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed/roi_MD_values.csv'
echo "Subject,UF_L_MD,UF_R_MD,DC_L_MD,DC_R_MD" > $OUTPUT

for subj in $SUBJECT_DIR/*; do
    if [[ -d "$subj" ]]; then

        ID=$(basename "$subj")
        MD_IMAGE="$subj/tbdti_MD.nii.gz"

        if [[ ! -f "$MD_IMAGE" ]]; then
            echo "Skipping $ID (no MD image)"
            continue
        fi

        echo "Extracting MD for $ID..."

        UF_L_MD=$(fslmeants -i $MD_IMAGE -m $UF_L)
        UF_R_MD=$(fslmeants -i $MD_IMAGE -m $UF_R)
        DC_L_MD=$(fslmeants -i $MD_IMAGE -m $DC_L)
        DC_R_MD=$(fslmeants -i $MD_IMAGE -m $DC_R)

        echo "$ID,$UF_L_MD,$UF_R_MD,$DC_L_MD,$DC_R_MD" >> $OUTPUT
    fi
done

echo "Saved MD ROI table to $OUTPUT"
