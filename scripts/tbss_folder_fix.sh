#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
TBSS_DIR="$PROJECT_ROOT/TBSS_GROUP"
ORIGDATA="$TBSS_DIR/origdata"

cd "$TBSS_DIR"

mkdir -p RD L1 MD

for fa in "$ORIGDATA"/*.nii.gz; do
    fname=$(basename "$fa")

    # skip non-FA metrics
    case "$fname" in
        *_RD.nii.gz|*_L1.nii.gz|*_MD.nii.gz) continue ;;
    esac

    subj="${fname%.nii.gz}"

    RD_SRC="$ORIGDATA/${subj}_RD.nii.gz"
    L1_SRC="$ORIGDATA/${subj}_L1.nii.gz"
    MD_SRC="$ORIGDATA/${subj}_MD.nii.gz"

    if [[ ! -f "$RD_SRC" || ! -f "$L1_SRC" || ! -f "$MD_SRC" ]]; then
        echo "[WARNING] Missing RD/L1/MD for $subj"
        continue
    fi

    cp "$RD_SRC" "RD/${subj}.nii.gz"
    cp "$L1_SRC" "L1/${subj}.nii.gz"
    cp "$MD_SRC" "MD/${subj}.nii.gz"
done

echo "[DONE] RD/L1/MD folders populated"
