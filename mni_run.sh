#!/bin/bash
set -euo pipefail

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"

RAW_DIR="$PROJECT_ROOT/data/raw"
ROI_DIR="$PROJECT_ROOT/data/rois"        
OUT_DIR="$PROJECT_ROOT/data/processed"

TEMPLATE="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"

OUT_CSV="$OUT_DIR/roi_metrics.csv"

# Write header once
if [ ! -f "$OUT_CSV" ]; then
  echo "subject,roi,metric,value" > "$OUT_CSV"
fi

# ==================================================
# LOOP OVER SUBJECTS (M*)
# ==================================================

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")
    echo "======================================"
    echo "Processing $ID"

    FA="$subj/rdti_FA.nii.gz"
    AD="$subj/rdti_AD.nii.gz"
    RD="$subj/rdti_RD.nii.gz"
    MD="$subj/rdti_MD.nii.gz"

    # Skip if FA missing
    if [[ ! -f "$FA" ]]; then
        echo "Skipping $ID (no rdti_FA.nii.gz)"
        continue
    fi

    SUBJ_OUT="$OUT_DIR/$ID"
    mkdir -p "$SUBJ_OUT"

    # ==================================================
    # 1. FA → MNI REGISTRATION
    # ==================================================

    flirt \
      -in "$FA" \
      -ref "$TEMPLATE" \
      -omat "$SUBJ_OUT/fa2mni_affine.mat" \
      -out "$SUBJ_OUT/fa2mni_affine.nii.gz" \
      -dof 12

    fnirt \
      --in="$FA" \
      --aff="$SUBJ_OUT/fa2mni_affine.mat" \
      --ref="$TEMPLATE" \
      --cout="$SUBJ_OUT/fa2mni_warp.nii.gz" \
      --iout="$SUBJ_OUT/rdti_FA_MNI.nii.gz" \
      --config=FA_2_FMRIB58_1mm

    # ==================================================
    # 2. APPLY FA WARP TO AD / RD / MD
    # ==================================================

    for METRIC in AD RD MD; do
        applywarp \
          --in="$subj/rdti_${METRIC}.nii.gz" \
          --ref="$TEMPLATE" \
          --warp="$SUBJ_OUT/fa2mni_warp.nii.gz" \
          --out="$SUBJ_OUT/rdti_${METRIC}_MNI.nii.gz"
    done

    # ==================================================
    # 3. ROI EXTRACTION (MEAN VALUES)
    # ==================================================

    for ROI in UF_L UF_R DC_L DC_R; do
        for METRIC in FA AD RD MD; do

            MEAN=$(fslstats \
              "$SUBJ_OUT/rdti_${METRIC}_MNI.nii.gz" \
              -k "$ROI_DIR/${ROI}.nii.gz" -M)

            echo "${ID},${ROI},${METRIC},${MEAN}" >> "$OUT_CSV"

        done
    done

done

echo
echo "======================================"
echo "ROI ANALYSIS COMPLETE"
echo "Output CSV:"
echo "$OUT_CSV"
