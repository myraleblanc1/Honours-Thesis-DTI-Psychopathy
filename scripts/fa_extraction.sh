#!/usr/bin/env bash
set -euo pipefail

BASEDIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW="$BASEDIR/data/raw"
ROIS="$BASEDIR/data/rois"
OUT="$BASEDIR/data/processed/roi_FA_to_target"

mkdir -p "$OUT"

CSV="$OUT/roi_FA_results.csv"
echo "subject,roi,FA_mean,FA_sd,nvox" > "$CSV"

for SUBJ in "$RAW"/*; do
    [ -d "$SUBJ" ] || continue
    ID=$(basename "$SUBJ")

    FA="$SUBJ/rdti_FA_FA_to_target.nii.gz"

    if [ ! -s "$FA" ]; then
        echo "[WARN] Missing FA_to_target for $ID, skipping"
        continue
    fi

    echo "[SUBJECT] $ID"

    SUBJ_OUT="$OUT/$ID"
    mkdir -p "$SUBJ_OUT"

    for ROI in UF_L UF_R DC_L DC_R; do
        ROI_SRC="$ROIS/${ROI}.nii.gz"
        ROI_RES="$SUBJ_OUT/${ROI}_resampled.nii.gz"

        if [ ! -s "$ROI_SRC" ]; then
            echo "[WARN] Missing ROI $ROI_SRC"
            continue
        fi

        # --- RESAMPLE ROI INTO THIS SUBJECT'S FA SPACE ---
        flirt \
          -in "$ROI_SRC" \
          -ref "$FA" \
          -applyxfm \
          -usesqform \
          -interp nearestneighbour \
          -out "$ROI_RES"

        # --- EXTRACT FA ---
        stats=$(fslstats "$FA" -k "$ROI_RES" -M -S -V)

        mean=$(echo "$stats" | awk '{print $1}')
        sd=$(echo "$stats" | awk '{print $2}')
        nvox=$(echo "$stats" | awk '{print $3}')

        if [ "$nvox" -eq 0 ]; then
            echo "[WARN] Zero voxels for $ID $ROI"
            continue
        fi

        echo "$ID,$ROI,$mean,$sd,$nvox" >> "$CSV"
    done
done

echo "[DONE] ROI extraction complete"
"Saved FA ROI table to $OUTPUT"
