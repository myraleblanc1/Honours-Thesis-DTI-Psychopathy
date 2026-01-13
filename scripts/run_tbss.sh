#!/bin/bash
set -euo pipefail

# ============================
# PATHS
# ============================
PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW_DIR="$PROJECT_ROOT/data/raw"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"

SUBJECT_LIST="$TBSS_DIR/subject_order.txt"

# ============================
# 0. SETUP
# ============================
mkdir -p "$TBSS_DIR"
cd "$TBSS_DIR"

echo "Running GROUP-level TBSS (robust subject mapping)"

# Reset inputs
rm -f *_FA.nii.gz
rm -f "$SUBJECT_LIST"

# ============================
# 1. COLLECT FA FILES + RECORD ORDER
# ============================
echo "Collecting FA images and recording subject order..."

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")
    FA="$subj/rdti_FA.nii.gz"

    if [[ ! -f "$FA" ]]; then
        echo "Skipping $ID (no FA)"
        continue
    fi

    cp "$FA" "${ID}_FA.nii.gz"
    echo "$ID" >> "$SUBJECT_LIST"
done

N=$(wc -l < "$SUBJECT_LIST")
echo "Found $N subjects with FA"

if [[ "$N" -lt 2 ]]; then
    echo "ERROR: Need at least 2 subjects for TBSS"
    exit 1
fi

echo "Subject order saved to:"
echo "$SUBJECT_LIST"

# ============================
# 2. RUN TBSS (FA)
# ============================
tbss_1_preproc *_FA.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
tbss_4_prestats 0.2

# ============================
# 3. PROJECT NON-FA METRICS
# ============================
tbss_non_FA RD
tbss_non_FA L1
tbss_non_FA MD

# ============================
# 4. WRITE SUBJECT-WISE TBDTI FILES (ORDER-SAFE)
# ============================
echo "Writing tbdti files back to subject folders..."

cd stats

i=0
while read -r ID; do
    subj_dir="$RAW_DIR/$ID"

    echo "  → $ID (volume $i)"

    fslroi all_FA_skeletonised.nii.gz "$subj_dir/tbdti_FA.nii.gz" $i 1
    fslroi all_RD_skeletonised.nii.gz "$subj_dir/tbdti_RD.nii.gz" $i 1
    fslroi all_L1_skeletonised.nii.gz "$subj_dir/tbdti_L1.nii.gz" $i 1
    fslroi all_MD_skeletonised.nii.gz "$subj_dir/tbdti_MD.nii.gz" $i 1

    ((i++))
done < "$SUBJECT_LIST"

# ============================
# 5. FINAL OUTPUTS
# ============================
echo
echo "TBSS COMPLETE"
echo "Group skeleton:"
echo "$TBSS_DIR/stats/mean_FA_skeleton.nii.gz"
echo
echo "Subject order file:"
echo "$SUBJECT_LIST"
echo
echo "Valid tbdti_* files written to each subject folder"
