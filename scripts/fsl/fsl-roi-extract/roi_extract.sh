#!/usr/bin/env bash
set -euo pipefail

SUBJDIR="${1:-$(pwd)}"
cd "$SUBJDIR"

mkdir -p derivatives/roi derivatives/qc logs
LOG="logs/roi_extract_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOG") 2>&1

echo "[INFO] Started: $(date -Is)"
echo "[INFO] Working dir: $SUBJDIR"
echo "[ENV] FSLDIR=${FSLDIR:-?}"
[ -f "$FSLDIR/etc/fslversion" ] && echo "[ENV] FSL version: $(cat "$FSLDIR/etc/fslversion")"
which flirt; which fslmaths; which fslstats || true

FA_TMPL="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"
JHU_LABELS="$FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz"

# ---------- helpers ----------
pick(){ for p in "$@"; do f=$(ls $p 2>/dev/null | head -n1 || true); [ -n "${f:-}" ] && { echo "$f"; return; }; done; }

# ---------- detect inputs ----------
echo "[STEP] Detecting diffusion maps…"
FA_STD=$(pick tbdti_FA.nii tbdti_FA.nii.gz)
MD_STD=$(pick tbdti_MD.nii tbdti_MD.nii.gz)
RD_STD=$(pick tbdti_RD.nii tbdti_RD.nii.gz)
AD_STD=$(pick tbdti_L1.nii tbdti_L1.nii.gz)

FA_NATIVE=$(pick rdti_FA.nii rdti_FA.nii.gz)
MD_NATIVE=$(pick rdti_MD.nii rdti_MD.nii.gz)
RD_NATIVE=$(pick rdti_RD.nii rdti_RD.nii.gz)
AD_NATIVE=$(pick rdti_L1.nii rdti_L1.nii.gz)

MODE=""
if [ -n "${FA_STD:-}" ] && [ -n "${MD_STD:-}" ] && [ -n "${RD_STD:-}" ] && [ -n "${AD_STD:-}" ]; then
  MODE="STANDARD"
  REF="$FA_STD"; FA="$FA_STD"; MD="$MD_STD"; RD="$RD_STD"; AD="$AD_STD"
  echo "[INFO] Using standard-space maps: $FA_STD"
elif [ -n "${FA_NATIVE:-}" ] && [ -n "${MD_NATIVE:-}" ] && [ -n "${RD_NATIVE:-}" ] && [ -n "${AD_NATIVE:-}" ]; then
  MODE="NATIVE"
  echo "[INFO] Using native-space maps; registering to MNI (affine)…"
  flirt -in "$FA_NATIVE" -ref "$FA_TMPL" -omat subj2MNI.mat -dof 12 -cost corratio
  for pair in "FA $FA_NATIVE" "MD $MD_NATIVE" "RD $RD_NATIVE" "L1 $AD_NATIVE"; do
    set -- $pair; m="$1"; f="$2"
    flirt -in "$f" -ref "$FA_TMPL" -out derivatives/roi/${m}_inMNI.nii.gz -applyxfm -init subj2MNI.mat
  done
  REF="derivatives/roi/FA_inMNI.nii.gz"
  FA="$REF"; MD="derivatives/roi/MD_inMNI.nii.gz"; RD="derivatives/roi/RD_inMNI.nii.gz"; AD="derivatives/roi/L1_inMNI.nii.gz"
else
  echo "[ERROR] Could not find tbdti_* or rdti_* (FA/MD/RD/L1)."; ls -1; exit 1
fi

# ---------- atlas label indices (hard-coded from your atlasq output) ----------
echo "[STEP] Using hard-coded JHU label indices…"
UF_L_IDX=48
UF_R_IDX=47
CgC_L_IDX=36
CgC_R_IDX=35
echo "[INFO] Indices: UF_L=$UF_L_IDX UF_R=$UF_R_IDX CgC_L=$CgC_L_IDX CgC_R=$CgC_R_IDX"

# ---------- build masks & resample to REF grid ----------
mk_mask(){  # $1 idx  $2 name
  fslmaths "$JHU_LABELS" -thr "$1" -uthr "$1" -bin derivatives/roi/${2}_mask_1mm.nii.gz
  flirt -in derivatives/roi/${2}_mask_1mm.nii.gz -ref "$REF" -out derivatives/roi/${2}_mask_ref.nii.gz \
        -applyxfm -usesqform -interp nearestneighbour
}
mk_mask "$UF_L_IDX"  JHU_UF_L
mk_mask "$UF_R_IDX"  JHU_UF_R
mk_mask "$CgC_L_IDX" JHU_CgC_L
mk_mask "$CgC_R_IDX" JHU_CgC_R

# ---------- extract stats ----------
SUBJECT="$(basename "$SUBJDIR")"
CSV="derivatives/roi/roi_metrics_${SUBJECT}_${MODE,,}.csv"
echo "subject,space,roi,metric,mean,sd,voxels,mm3" > "$CSV"

extract(){  # $1 img  $2 roi  $3 metric
  stats=$(fslstats "$1" -k derivatives/roi/${2}_mask_ref.nii.gz -M -S -V)
  echo "$SUBJECT,$MODE,$2,$3,$(echo $stats | awk '{print $1","$2","$3","$4}')" >> "$CSV"
}

for ROI in JHU_UF_L JHU_UF_R JHU_CgC_L JHU_CgC_R; do
  extract "$FA" "$ROI" FA
  extract "$MD" "$ROI" MD
  extract "$RD" "$ROI" RD
  extract "$AD" "$ROI" AD
done

# quick QC images (optional)
slicer "$REF" derivatives/roi/JHU_UF_L_mask_ref.nii.gz -a derivatives/qc/${SUBJECT}_UF_L.png 2>/dev/null || true
slicer "$REF" derivatives/roi/JHU_UF_R_mask_ref.nii.gz -a derivatives/qc/${SUBJECT}_UF_R.png 2>/dev/null || true
slicer "$REF" derivatives/roi/JHU_CgC_L_mask_ref.nii.gz -a derivatives/qc/${SUBJECT}_CgC_L.png 2>/dev/null || true
slicer "$REF" derivatives/roi/JHU_CgC_R_mask_ref.nii.gz -a derivatives/qc/${SUBJECT}_CgC_R.png 2>/dev/null || true

echo "[DONE] CSV: $CSV"
