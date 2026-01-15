
for f in origdata/*_FA.nii.gz; do
    base=$(basename "$f" _FA.nii.gz)
    mv "$f" "origdata/${base}.nii.gz"
done
