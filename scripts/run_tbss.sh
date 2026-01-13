#!/bin/bash
set -euo pipefail

# ============================
# PATHS (EDIT IF NEEDED)
# ============================
PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW_DIR="$PROJECT_ROOT/data/raw"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"

# ============================
# 0. SETUP
# ============================
mkdir -p "$TBSS_DIR"
cd "$TBSS_DIR"

echo "Running GROUP-level TBSS in:"
echo "$TBSS_DIR"

# ============================
# 1. COLLECT FA FILES
# ============================
echo "Collecting FA images..."

rm -f *_FA.nii.gz

i=1
for subj in "$RAW_DIR"/M*; do
    FA="$subj/rdti_FA.nii.gz"

    if [[ ! -f "$FA" ]]; then
        echo "WARNING: Missing FA for $(basename "$subj"), skipping"
        continue
    fi

    printf -v id "%03d" $i
    cp "$FA" "subj${id}_FA.nii.gz"
    ((i++))
done

N=$(ls *_FA.nii.gz | wc -l)
echo "Found $N FA images"

if [[ "$N" -lt 2 ]]; then
    echo "ERROR: Need at least 2 subjects for TBSS"
    exit 1
fi

# ============================
# 2. RUN TBSS (FA)
# ============================
echo "Running tbss_1_preproc"
tbss_1_preproc *.nii.gz

echo "Running tbss_2_reg"
tbss_2_reg -T

echo "Running tbss_3_postreg"
tbss_3_postreg -S

echo "Running tbss_4_prestats"
tbss_4_prestats 0.2

# ============================
# 3. PROJECT NON-FA METRICS
# ============================
echo "Projecting RD, L1 (AD), and MD"

tbss_non_FA RD
tbss_non_FA L1
tbss_non_FA MD

# ============================
# 4. WRITE SUBJECT-WISE TBDTI FILES
# ============================
echo "Writing tbdti files back to subject folders..."

cd stats

# Get subject list in SAME ORDER as FA inputs
SUBJECTS=($(ls "$RAW_DIR" | grep '^M'))

for ((i=0; i<${#SUBJECTS[@]}; i++)); do
    subj="${SUBJECTS[$i]}"
    subj_dir="$RAW_DIR/$subj"

    printf -v idx "%d" $((i+1))

    echo "  → $subj"

    fslroi all_FA_skeletonised.nii.gz  "$subj_dir/tbdti_FA.nii.gz"  $i 1
    fslroi all_RD_skeletonised.nii.gz  "$subj_dir/tbdti_RD.nii.gz"  $i 1
    fslroi all_L1_skeletonised.nii.gz  "$subj_dir/tbdti_L1.nii.gz"  $i 1
    fslroi all_MD_skeletonised.nii.gz  "$subj_dir/tbdti_MD.nii.gz"  $i 1
done

# ============================
# 5. FINAL OUTPUTS
# ============================
echo
echo "TBSS COMPLETE"
echo "Group skeleton:"
echo "$TBSS_DIR/stats/mean_FA_skeleton.nii.gz"
echo
echo "Valid tbdti_* files written to each subject folder"
