cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy
mkdir -p TBSS_GROUP/rois_skel

for roi in data/rois/*.nii.gz; do
    name=$(basename "$roi" .nii.gz)

    fslmaths "$roi" \
        -mas TBSS_GROUP/stats/mean_FA_skeleton.nii.gz \
        TBSS_GROUP/rois_skel/${name}_skel.nii.gz
done
