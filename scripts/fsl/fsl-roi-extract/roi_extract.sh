#!/usr/bin/env bash
set -uo pipefail
# NOTE: deliberately NOT using -e (do not exit on single-subject failure)

# ------------------
# PATHS
# ------------------
BASEDIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW="$BASEDIR/data/raw"
OUTDIR="$BASEDIR/data/processed/roi_batch_FA"

FA_TMPL="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"

mkdir -p "$OUTDIR"/group_csv "$OUTDIR"/qc

LOG="$OUTDIR/batch_FA_extract_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOG") 2>&1

echo "[INFO] FA-only ROI extraction started: $(date)"

# ------------------
# ROI DEFINITIONS
# ------------------
declare -A ROIS
ROIS["JHU_UF_L"]=21
ROIS["JHU_UF_R"]=22
ROIS["JHU_CgC_L"]=31
ROIS["JHU_CgC_R"]=32

CSV="$OUTDIR/group_csv/roi_FA_ALL_SUBJECTS.csv"
echo "subject,roi,FA_mean,FA_sd,nvox" > "$CSV"

# ------------------
# FUNCTION: extract FA safely
# ------------------
extract_fa () {
    local IMG="$1"
    local MASK="$2"
    local ID="$3"
    local ROI="$4"

    if [ ! -s "$IMG" ]; then
        echo "[WARN] Empty FA image for $ID ($ROI), skipping"
        return
    fi

    if [ ! -s "$MASK" ]; then
        echo "[WARN] Missing ROI mask for $ID ($ROI), skipping"
        return
    fi

    stats=$(fslstats "$IMG" -k "$MASK" -M -S -V 2>/dev/null || true)

    if [ -z "$stats" ]; then
        echo "[WARN] fslstats failed for $ID ($ROI)"
        return
    fi

    mean=$(echo "$stats" | awk '{print $1}')
    sd=$(echo "$stats" | awk '{print $2}')
    nvox=$(echo "$stats" | awk '{print $3}')

    echo "$ID,$ROI,$mean,$sd,$nvox" >> "$CSV"
}

# ------------------
# MAIN LOOP
# ------------------
for SUBJ in "$RAW"/*; do
    [ -d "$SUBJ" ] || continue
    ID=$(basename "$SUBJ")

    echo "[SUBJECT] $ID"

    # ------------------
    # FIND FA FILE
    # ------------------
    FA_IMG=""

    for f in "$SUBJ"/tbdti_FA*.nii* "$SUBJ"/rdti_FA*.nii*; do
        if [ -s "$f" ]; then
            FA_IMG="$f"
            break
        fi
    done

    if [ -z "$FA_IMG" ]; then
        echo "[WARN] No valid FA file for $ID, skipping subject"
        continue
    fi

    # ------------------
    # REGISTER IF NEEDED
    # ------------------
    SUBJ_OUT="$OUTDIR/$ID"
    mkdir -p "$SUBJ_OUT"

    FA_MNI="$SUBJ_OUT/FA_MNI.nii.gz"

    if [[ "$FA_IMG" == *tbdti_FA* ]]; then
        cp "$FA_IMG" "$FA_MNI"
    else
        MAT="$SUBJ_OUT/subj2MNI.mat"

        flirt -in "$FA_IMG" -ref "$FA_TMPL" -omat "$MAT" -dof 12 2>/dev/null || {
            echo "[WARN] Registration failed for $ID, skipping subject"
            continue
        }

        flirt -in "$FA_IMG" -ref "$FA_TMPL" -applyxfm -init "$MAT" -out "$FA_MNI" 2>/dev/null || {
            echo "[WARN] Applyxfm failed for $ID, skipping subject"
            continue
        }
    fi

    if [ ! -s "$FA_MNI" ]; then
        echo "[WARN] FA_MNI empty for $ID, skipping subject"
        continue
    fi

    # ------------------
    # ROI MASKS + EXTRACTION
    # ------------------
    for ROI in "${!ROIS[@]}"; do
        IDX=${ROIS[$ROI]}
        MASK="$SUBJ_OUT/${ROI}_mask.nii.gz"

        fslmaths "$FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz" \
            -thr "$IDX" -uthr "$IDX" -bin "$MASK" 2>/dev/null || continue

        extract_fa "$FA_MNI" "$MASK" "$ID" "$ROI"
    done

    echo "[DONE] $ID"
done

echo "[INFO] FA-only ROI extraction finished: $(date)"
