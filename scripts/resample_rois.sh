#resample rois to work


REF_FA="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw/M87114371/rdti_FA_FA_to_target.nii.gz"
ROI_DIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois"

flirt -in $ROI_DIR/UF_L.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/UF_L_resampled.nii.gz
flirt -in $ROI_DIR/UF_R.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/UF_R_resampled.nii.gz
flirt -in $ROI_DIR/DC_L.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/DC_L_resampled.nii.gz
flirt -in $ROI_DIR/DC_R.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/DC_R_resampled.nii.gz
