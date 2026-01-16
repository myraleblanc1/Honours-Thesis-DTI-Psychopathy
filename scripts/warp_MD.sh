#!/bin/bash
set -euo pipefail

# ============================================================
# Warp MD, RD, and L1 to target space using FA warp for all subjects
# ============================================================

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW_DIR="${PROJECT_ROOT}/data/raw"

cd "$RAW_DIR"

# Metrics to warp
METRICS=("MD" "RD" "L1")

for SUBJ_DIR in M*; do
    echo "=============================================="
    echo "Processing ${SUBJ_DIR}"
    echo "=============================================="

    cd "${RAW_DIR}/${SUBJ_DIR}"

    # Safety checks
    if [[ ! -f rdti_FA_FA_to_target_warp.nii.gz ]]; then
        echo " Missing warp file for ${SUBJ_DIR}, skipping"
        cd "$RAW_DIR"
        continue
    fi

    if [[ ! -f target.nii.gz ]]; then
        echo " Missing target.nii.gz for ${SUBJ_DIR}, skipping"
        cd "$RAW_DIR"
        continue
    fi

    for METRIC in "${METRICS[@]}"; do
        IN_FILE="rdti_${METRIC}.nii.gz"
        OUT_FILE="rdti_${METRIC}_to_target.nii.gz"

        if [[ ! -f "$IN_FILE" ]]; then
            echo "  ${IN_FILE} not found, skipping"
            continue
        fi

        echo "→ Warping ${IN_FILE}"

        applywarp \
            --in="$IN_FILE" \
            --ref=target.nii.gz \
            --warp=rdti_FA_FA_to_target_warp.nii.gz \
            --out="$OUT_FILE" \
            --interp=spline
    done

    cd "$RAW_DIR"
done

echo "All diffusion metrics warped successfully"

