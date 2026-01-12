ROI_DIR='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/rois'
TBSS_STATS='/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data'

mkdir -p $ROI_DIR

ATLAS="$FSLDIR/data/atlases/JHU/JHU-ICBM-tracts-maxprob-thr0-1mm.nii.gz"
SKELETON="$TBSS_STATS/mean_FA_skeleton.nii.gz"
# ========================
# 1. Creates volumetric ROIs
# ========================
# UF Left (label 21)
fslmaths $ATLAS -thr 21 -uthr 21 -bin $ROI_DIR/UF_L.nii.gz

# UF Right (label 22)
fslmaths $ATLAS -thr 22 -uthr 22 -bin $ROI_DIR/UF_R.nii.gz

# Dorsal Cingulum Left (CgC, label 31)
fslmaths $ATLAS -thr 31 -uthr 31 -bin $ROI_DIR/DC_L.nii.gz

# Dorsal Cingulum Right (CgC, label 32)
fslmaths $ATLAS -thr 32 -uthr 32 -bin $ROI_DIR/DC_R.nii.gz
# ==================================
# 2. Resamples ROIs to TBSS space
# ==================================
for roi in UF_L UF_R DC_L DC_R; do
    flirt \
      -in  $ROI_DIR/${roi}.nii.gz \
      -ref $SKELETON \
      -out $ROI_DIR/${roi}_resampled.nii.gz \
      -applyxfm \
      -interp nearestneighbour
done

# =========================
# 3. Create group-level skeleton ROI masks
# =========================

for roi in UF_L UF_R DC_L DC_R; do
    fslmaths \
      $ROI_DIR/${roi}_resampled.nii.gz \
      -mul $SKELETON \
      $ROI_DIR/${roi}_skel.nii.gz
done

# =========================
# 4. Sanity checks
# =========================

echo "Voxel counts in skeleton ROIs:"
for roi in UF_L UF_R DC_L DC_R; do
    echo -n "${roi}: "
    fslstats $ROI_DIR/${roi}_skel.nii.gz -V
done

echo "Done. Skeleton ROI masks created."
