#Restoring original masks creation script that uses 1mm template. 
ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'
mkdir -p $ROI_DIR

ATLAS="$FSLDIR/data/atlases/JHU/JHU-ICBM-tracts-maxprob-thr0-1mm.nii.gz"

# UF Left (label 21)
fslmaths $ATLAS -thr 21 -uthr 21 -bin $ROI_DIR/UF_L.nii.gz

# UF Right (label 22)
fslmaths $ATLAS -thr 22 -uthr 22 -bin $ROI_DIR/UF_R.nii.gz

# Dorsal Cingulum Left (CgC, label 31)
fslmaths $ATLAS -thr 31 -uthr 31 -bin $ROI_DIR/DC_L.nii.gz

# Dorsal Cingulum Right (CgC, label 32)
fslmaths $ATLAS -thr 32 -uthr 32 -bin $ROI_DIR/DC_R.nii.gz

#resample rois to work


REF_FA="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw/M87114371/rdti_FA_FA_to_target.nii.gz"
ROI_DIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois"

flirt -in $ROI_DIR/UF_L.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/UF_L_resampled.nii.gz
flirt -in $ROI_DIR/UF_R.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/UF_R_resampled.nii.gz
flirt -in $ROI_DIR/DC_L.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/DC_L_resampled.nii.gz
flirt -in $ROI_DIR/DC_R.nii.gz -ref $REF_FA -applyxfm -usesqform -out $ROI_DIR/DC_R_resampled.nii.gz
