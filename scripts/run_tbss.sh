#!/bin/bash
set -euo pipefail

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW_DIR="$PROJECT_ROOT/data/raw"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"

mkdir -p "$TBSS_DIR"
cd "$TBSS_DIR"

echo "Running group-level TBSS (preserving subject IDs)"

# ----------------------------
# 1. Collect FA images
# ----------------------------
rm -f *_FA.nii.gz

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")
    FA="$subj/rdti_FA.nii.gz"

    if [[ ! -f "$FA" ]]; then
        echo "WARNING: Missing FA for $ID, skipping"
        continue
    fi

    cp "$FA" "${ID}_FA.nii.gz"
done

echo "Found $(ls *_FA.nii.gz | wc -l) FA images"

# ----------------------------
# 2. Run TBSS
# ----------------------------
tbss_1_preproc *_FA.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
tbss_4_prestats 0.2

# ----------------------------
# 3. Project non-FA metrics
# ----------------------------
tbss_non_FA RD
tbss_non_FA L1
tbss_non_FA MD

echo "TBSS complete"
echo "Group skeleton:"
echo "$TBSS_DIR/stats/mean_FA_skeleton.nii.gz"
