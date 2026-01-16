#!/bin/bash
set -euo pipefail

# ============================================================
# PROJECT PATHS
# ============================================================

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"

RAW_DIR="$PROJECT_ROOT/data/raw"
ROI_DIR="$PROJECT_ROOT/data/rois"              # 2mm ROIs
OUT_DIR="$PROJECT_ROOT/data/processed"

mkdir -p "$OUT_DIR"

OUT_CSV="$OUT_DIR/roi_metrics.csv"

# ============================================================
# FNIRT SETTINGS (1mm ONLY – guaranteed to exist)
# ============================================================

FNIRT_REF="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"
FNIRT_CFG="FA_2_FMRIB58_1mm"

# ============================================================
# FINAL OUTPUT GRID (2mm, guaranteed to exist)
# ============================================================

REF_2MM="$FSLDIR/data/standard/MNI152_T1_2mm.nii.gz"

# ============================================================
# CSV HEADER
# ============================================================

if [ ! -f "$OUT_CSV" ]; then
  echo "subject,roi,metric,value" > "$OUT_CSV"
fi

# ============================================================
# SUBJECT LOOP
# ============================================================

for subj in "$RAW_DIR"/M*; do
    ID=$(basename "$subj")
    echo "======================================"
    echo "Processing $ID"

    FA="$subj/rdti_FA.nii.gz"
    L1="$subj/rdti_L1.nii.gz"   # AD
    RD="$subj/rdti_RD.nii.gz"
    MD="$subj/rdti_MD.nii.gz"

    if [[ ! -f "$FA" ]]; then
        echo "Skipping $ID (missing rdti_FA.nii.gz)"
        continue
    fi

    SUBJ_OUT="$OUT_DIR/$ID"
    mkdir -p "$SUBJ_OUT"

    # --------------------------------------------------------
    # 1. FA → MNI (1mm FNIRT)
    # --------------------------------------------------------

    flirt \
      -in "$FA" \
      -ref "$FNIRT_REF" \
      -omat "$SUBJ_OUT/fa2mni_affine.mat" \
      -out "$SUBJ_OUT/fa_affine_1mm.nii.gz" \
      -dof 12

    fnirt \
      --in="$FA" \
      --aff="$SUBJ_OUT/fa2mni_affine.mat" \
      --ref="$FNIRT_REF" \
      --config="$FNIRT_CFG" \
      --cout="$SUBJ_OUT/fa2mni_warp_1mm.nii.gz" \
      --iout="$SUBJ_OUT/rdti_FA_MNI_1mm.nii.gz"

    # --------------------------------------------------------
    # 2. Apply warp → 2mm MNI grid
    # --------------------------------------------------------

    for METRIC in FA L1 RD MD; do
        applywarp \
          --in="$subj/rdti_${METRIC}.nii.gz" \
          --warp="$SUBJ_OUT/fa2mni_warp_1mm.nii.gz" \
          --ref="$REF_2MM" \
          --out="$SUBJ_OUT/rdti_${METRIC}_MNI_2mm.nii.gz"
    done

    # --------------------------------------------------------
    # 3. ROI EXTRACTION (2mm)
    # --------------------------------------------------------

    for ROI in UF_L UF_R DC_L DC_R; do
        FA_M=$(fslstats "$SUBJ_OUT/rdti_FA_MNI_2mm.nii.gz" -k "$ROI_DIR/${ROI}.nii.gz" -M)
        AD_M=$(fslstats "$SUBJ_OUT/rdti_L1_MNI_2mm.nii.gz" -k "$ROI_DIR/${ROI}.nii.gz" -M)
        RD_M=$(fslstats "$SUBJ_OUT/rdti_RD_MNI_2mm.nii.gz" -k "$ROI_DIR/${ROI}.nii.gz" -M)
        MD_M=$(fslstats "$SUBJ_OUT/rdti_MD_MNI_2mm.nii.gz" -k "$ROI_DIR/${ROI}.nii.gz" -M)

        echo "${ID},${ROI},FA,${FA_M}" >> "$OUT_CSV"
        echo "${ID},${ROI},AD,${AD_M}" >> "$OUT_CSV"
        echo "${ID},${ROI},RD,${RD_M}" >> "$OUT_CSV"
        echo "${ID},${ROI},MD,${MD_M}" >> "$OUT_CSV"
    done
done

echo "======================================"
echo "DONE"
echo "Results written to:"
echo "$OUT_CSV"
