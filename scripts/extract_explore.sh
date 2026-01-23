#!/usr/bin/env bash
set -uo pipefail
# deliberately NOT using -e

# ------------------
# PATHS
# ------------------
BASEDIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW="$BASEDIR/data/raw"
OUTDIR="$BASEDIR/data/processed/roi_batch_diffusivity"

FSL_FA_TMPL="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"

mkdir -p "$OUTDIR"/group_csv "$OUTDIR"/qc

LOG="$OUTDIR/batch_diffusivity_extract_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOG") 2>&1

echo "[INFO] L1/MD/RD ROI extraction started: $(date)"

# ------------------
# ROI DEFINITIONS (JHU atlas indices)
# ------------------
declare -A ROIS
ROIS["JHU_UF_L"]=21
ROIS["JHU_UF_R"]=22
ROIS["JHU_CgC_L"]=31
ROIS["JHU_CgC_R"]=32

# ------------------
# OUTPUT CSV
# ------------------
CSV="$OUTDIR/group_csv/roi_L1_MD_RD_ALL_SUBJECTS.csv"
echo "subject,metric,roi,mean,sd,nvox" > "$CSV"

# ------------------
# FUNCTION: safe extraction
# ------------------
extract_metric () {
    local IMG="$1"
    local MASK="$2"
    local ID="$3"
    local METRIC="$4"
    local ROI="$5"

    if [ ! -s "$IMG" ]; then
        echo "[WARN] Missing image for $ID $METRIC"
        return
    fi

    stats=$(fslstats "$IMG" -k "$MASK" -M -S -V 2>/dev/null || true)

    if [ -z "$stats" ]; then
        echo "[WARN] fslstats failed for $ID $METRIC $ROI"
        return
    fi

    mean=$(echo "$stats" | awk '{print $1}')
    sd=$(echo "$stats" | awk '{print $2}')
    nvox=$(echo "$stats" | awk '{print $3}')

    echo "$ID,$METRIC,$ROI,$mean,$sd,$nvox" >> "$CSV"
}

# ------------------
# MAIN LOOP
# ------------------
for SUBJ in "$RAW"/*; do
    [ -d "$SUBJ" ] || continue
    ID=$(basename "$SUBJ")

    echo "[SUBJECT] $ID"

    # ------------------
    # FIND DIFFUSIVITY FILES
    # ------------------
    L1_IMG=""
    MD_IMG=""
    RD_IMG=""

    for f in "$SUBJ"/tbdti_L1*.nii* "$SUBJ"/rdti_L1*.nii*; do
        [ -s "$f" ] && L1_IMG="$f" && break
    done

    for f in "$SUBJ"/tbdti_MD*.nii* "$SUBJ"/rdti_MD*.nii*; do
        [ -s "$f" ] && MD_IMG="$f" && break
    done

    for f in "$SUBJ"/tbdti_RD*.nii* "$SUBJ"/rdti_RD*.nii*; do
        [ -s "$f" ] && RD_IMG="$f" && break
    done

    if [ -z "$L1_IMG" ] && [ -z "$MD_IMG" ] && [ -z "$RD_IMG" ]; then
        echo "[WARN] No diffusivity maps for $ID, skipping subject"
        continue
    fi

    SUBJ_OUT="$OUTDIR/$ID"
    mkdir -p "$SUBJ_OUT"

    # ------------------
    # REGISTER METRICS TO MNI (IF NEEDED)
    # ------------------
    for METRIC in L1 MD RD; do
        IMG_VAR="${METRIC}_IMG"
        SRC_IMG="${!IMG_VAR}"

        [ -z "$SRC_IMG" ] && continue

        OUT_IMG="$SUBJ_OUT/${METRIC}_MNI.nii.gz"

        if [[ "$SRC_IMG" == *tbdti_* ]]; then
            cp "$SRC_IMG" "$OUT_IMG"
        else
            MAT="$SUBJ_OUT/subj2MNI.mat"

            flirt -in "$SRC_IMG" -ref "$FSL_FA_TMPL" -omat "$MAT" -dof 12 2>/dev/null || continue
            flirt -in "$SRC_IMG" -ref "$FSL_FA_TMPL" -applyxfm -init "$MAT" -out "$OUT_IMG" 2>/dev/null || continue
        fi
    done

    # ------------------
    # ROI MASKS + EXTRACTION
    # ------------------
    for ROI in "${!ROIS[@]}"; do
        IDX=${ROIS[$ROI]}
        MASK="$SUBJ_OUT/${ROI}_mask.nii.gz"

        fslmaths "$FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz" \
            -thr "$IDX" -uthr "$IDX" -bin "$MASK" 2>/dev/null || continue

        [ ! -s "$MASK" ] && continue

        for METRIC in L1 MD RD; do
            IMG="$SUBJ_OUT/${METRIC}_MNI.nii.gz"
            [ -s "$IMG" ] || continue

            extract_metric "$IMG" "$MASK" "$ID" "$METRIC" "$ROI"
        done
    done

    echo "[DONE] $ID"
done

echo "[INFO] L1/MD/RD ROI extraction finished: $(date)"
