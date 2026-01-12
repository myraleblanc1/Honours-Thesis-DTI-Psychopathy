#AD extraction script 

SUBJECT_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw'
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'

# Use the RESAMPLED ROI masks
UF_L="$ROI_DIR/UF_L_resampled.nii.gz"
UF_R="$ROI_DIR/UF_R_resampled.nii.gz"
DC_L="$ROI_DIR/DC_L_resampled.nii.gz"
DC_R="$ROI_DIR/DC_R_resampled.nii.gz"

OUTPUT='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed/roi_AD_values.csv'
echo "Subject,UF_L_AD,UF_R_AD,DC_L_AD,DC_R_AD" > $OUTPUT

for subj in $SUBJECT_DIR/*; do
    if [[ -d "$subj" ]]; then

        ID=$(basename "$subj")
        AD_IMAGE="$subj/tbdti_L1.nii.gz"

        if [[ ! -f "$AD_IMAGE" ]]; then
            echo "Skipping $ID (no AD image)"
            continue
        fi

        echo "Extracting AD for $ID..."

        UF_L_AD=$(fslmeants -i $AD_IMAGE -m $UF_L)
        UF_R_AD=$(fslmeants -i $AD_IMAGE -m $UF_R)
        DC_L_AD=$(fslmeants -i $AD_IMAGE -m $DC_L)
        DC_R_AD=$(fslmeants -i $AD_IMAGE -m $DC_R)

        echo "$ID,$UF_L_AD,$UF_R_AD,$DC_L_AD,$DC_R_AD" >> $OUTPUT
    fi
done

echo "Saved FA ROI table to $OUTPUT"
