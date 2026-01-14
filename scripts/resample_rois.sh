mkdir -p ../data/rois_mni152_2mm

for ROI in ../data/rois/*.nii.gz; do
  flirt \
    -in "$ROI" \
    -ref $FSLDIR/data/standard/MNI152_T1_2mm.nii.gz \
    -applyxfm \
    -interp nearestneighbour \
    -out ../data/rois_mni152_2mm/$(basename "$ROI")
done

