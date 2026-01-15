cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy

mkdir -p TBSS_GROUP/rois_tbss
mkdir -p TBSS_GROUP/rois_skel
#==================================
# Resample masks into TBSS space
#==================================
for roi in data/rois/*.nii.gz; do
    name=$(basename "$roi" .nii.gz)

    flirt \
      -in "$roi" \
      -ref TBSS_GROUP/stats/mean_FA_skeleton.nii.gz \
      -applyxfm \
      -init $FSLDIR/etc/flirtsch/ident.mat \
      -interp nearestneighbour \
      -out TBSS_GROUP/rois_tbss/${name}_tbss.nii.gz
done

#==================================
# Skeletonise the masks
#==================================
for roi in TBSS_GROUP/rois_tbss/*_tbss.nii.gz; do
    name=$(basename "$roi" _tbss.nii.gz)

    fslmaths "$roi" \
      -mas TBSS_GROUP/stats/mean_FA_skeleton.nii.gz \
      TBSS_GROUP/rois_skel/${name}_skel.nii.gz
done
