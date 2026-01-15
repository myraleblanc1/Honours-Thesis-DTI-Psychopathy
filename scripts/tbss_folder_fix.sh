#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"
ORIGDATA="$TBSS_DIR/origdata"

cd "$TBSS_DIR"

mkdir -p RD L1 MD

echo "[INFO] Matching non-FA maps to FA basenames..."

for fa in FA/*_FA.nii.gz; do
    fa_base=$(basename "$fa" .nii.gz)      # e.g. M87192571_FA
    subj="${fa_base%_FA}"                  # e.g. M87192571

    RD_SRC="$ORIGDATA/${subj}_RD.nii.gz"
    L1_SRC="$ORIGDATA/${subj}_L1.nii.gz"
    MD_SRC="$ORIGDATA/${subj}_MD.nii.gz"

    if [[ ! -f "$RD_SRC" || ! -f "$L1_SRC" || ! -f "$MD_SRC" ]]; then
        echo "[WARNING] Missing RD/L1/MD for $subj — skipping"
        continue
    fi

    cp "$RD_SRC" "RD/${fa_base}.nii.gz"
    cp "$L1_SRC" "L1/${fa_base}.nii.gz"
    cp "$MD_SRC" "MD/${fa_base}.nii.gz"

    echo "  ✔ $fa_base"
done

echo "[DONE] RD / L1 / MD filenames now match FA exactly."
