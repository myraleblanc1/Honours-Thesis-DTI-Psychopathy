#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# FSL ROI extractor (UF L/R, CgC L/R) for FA/MD/RD/AD with reproducible logging
# Usage (from the subject folder or pass a folder):
#   ./roi_extract.sh                       # uses $PWD
#   ./roi_extract.sh /mnt/c/path/to/subject
# The subject folder must contain either tbdti_* or rdti_* maps.
# -----------------------------------------------------------------------------

BASEDIR="${1:-$(pwd)}"
cd "$BASEDIR"

# Create a results and logs area inside the subject folder
mkdir -p derivatives/roi logs
LOGFILE="logs/roi_extract_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOGFILE") 2>&1

echo "[INFO] Started: $(date -Is)"
echo "[INFO] Working dir: $BASEDIR"

# --- Capture environment for reproducibility ---
echo "[ENV] Host: $(hostname)"
echo "[ENV] Kernel: $(uname -a)"
if [ -f /etc/os-release ]; then echo "[ENV] OS:"; cat /etc/os-release; fi
if [ -n "${FSLDIR:-}" ]; then
  echo "[ENV] FSLDIR=$FSLDIR"
  if [ -f "$FSLDIR/etc/fslversion" ]; then echo "[ENV] FSL version: $(cat $FSLDIR/etc/fslversion)"; fi
fi
which flirt || true
which fslmaths || true
which fslstats || true

FA_TMPL="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"
ATLAS_LABELS="$FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz"
ATLAS_NAME="JHU ICBM-DTI-81 White-Matter Labels"

pick() {
  for p in "$@"; do
    local f
    f=$(ls $p 2>/dev/null | head -n1 || true)
    [[ -n "${f:-}" ]] && { echo "$f"; return 0; }
  done
  return 1
}

get_idx() {
  local -a patterns=("$@")
  local listing
  if ! command -v atlasquery >/dev/null 2>&1; then
    echo "[ERROR] atlasquery not found. Ensure FSL is installed and sourced."; exit 1
  fi
  listing="$(atlasquery -a "$ATLAS_NAME" -l)"
  local pat
  for pat in "${patterns[@]}"; do
    local line idx
    line="$(printf "%s\n" "$listing" | grep -i -m1 "$pat" || true)"
    if [[ -n "$line" ]]; then
      idx="$(printf "%s\n" "$line" | awk '{for(i=1;i<=NF;i++){if($i+0==$i){print $i; exit}}}')"
      if [[ -n "$idx" ]]; then echo "$idx"; return 0; fi
    fi
  done
  echo "[ERROR] Could not resolve atlas index for patterns: ${patterns[*]}"; echo "$listing"; exit 1
}

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
if [[ -n "${FA_STD:-}" && -n "${MD_STD:-}" && -n "${RD_STD:-}" && -n "${AD_STD:-}" ]]; then
  MODE="STANDARD"; REF="$FA_STD"; FA="$FA_STD"; MD="$MD_STD"; RD="$RD_STD"; AD="$AD_STD"
  echo "[INFO] Using standard-space maps: $FA"
elif [[ -n "${FA_NATIVE:-}" && -n "${MD_NATIVE:-}" && -n "${RD_NATIVE:-}" && -n "${AD_NATIVE:-}" ]]; then
  MODE="NATIVE"; echo "[INFO] Using native-space maps: $FA_NATIVE"
  echo "[STEP] Registering native FA → template (affine)"
  flirt -in "$FA_NATIVE" -ref "$FA_TMPL" -omat subj2MNI.mat -dof 12 -cost corratio
  for pair in "FA $FA_NATIVE" "MD $MD_NATIVE" "RD $RD_NATIVE" "L1 $AD_NATIVE"; do
    set -- $pair; m="$1"; f="$2"
    flirt -in "$f" -ref "$FA_TMPL" -out derivatives/roi/${m}_inMNI.nii.gz -applyxfm -init subj2MNI.mat
  done
  REF="derivatives/roi/FA_inMNI.nii.gz"
  FA="$REF"; MD="derivatives/roi/MD_inMNI.nii.gz"; RD="derivatives/roi/RD_inMNI.nii.gz"; AD="derivatives/roi/L1_inMNI.nii.gz"
else
  echo "[ERROR] Could not find tbdti_* or rdti_* (FA/MD/RD/L1) in $BASEDIR"; ls -1; exit 1
fi

# Resolve atlas indices (UF L/R, Cingulum (cingulate gyrus) L/R)
echo "[STEP] Resolving atlas label indices…"
UF_L_IDX=$(get_idx "Uncinate fasciculus.*(L" "Uncinate.*Left" "Uncinate fasciculus L")
UF_R_IDX=$(get_idx "Uncinate fasciculus.*(R" "Uncinate.*Right" "Uncinate fasciculus R")
CgC_L_IDX=$(get_idx "Cingulum.*cingulate.*(L" "Cingulate gyrus.*Left" "Cingulum.*\\(L\\)")
CgC_R_IDX=$(get_idx "Cingulum.*cingulate.*(R" "Cingulate gyrus.*Right" "Cingulum.*\\(R\\)")
echo "[INFO] Indices → UF_L=$UF_L_IDX UF_R=$UF_R_IDX CgC_L=$CgC_L_IDX CgC_R=$CgC_R_IDX"

mk_mask () {
  local idx="$1"; local name="$2"
  fslmaths "$ATLAS_LABELS" -thr "$idx" -uthr "$idx" -bin derivatives/roi/${name}_mask_1mm.nii.gz
  flirt -in derivatives/roi/${name}_mask_1mm.nii.gz -ref "$REF" \
        -out derivatives/roi/${name}_mask_ref.nii.gz -applyxfm -usesqform -interp nearestneighbour
}

echo "[STEP] Building ROI masks relative to: $REF"
mk_mask "$UF_L_IDX"  JHU_UF_L
mk_mask "$UF_R_IDX"  JHU_UF_R
mk_mask "$CgC_L_IDX" JHU_CgC_L
mk_mask "$CgC_R_IDX" JHU_CgC_R

SUBJECT="$(basename "$BASEDIR")"
OUTCSV="derivatives/roi/roi_metrics_${SUBJECT}_${MODE,,}.csv"
echo "subject,space,roi,metric,mean,sd,voxels,mm3" > "$OUTCSV"

extract () {
  local img="$1"; local roi="$2"; local metric="$3"; local stats mean sd vox mm3
  stats=$(fslstats "$img" -k derivatives/roi/${roi}_mask_ref.nii.gz -M -S -V)
  mean=$(echo "$stats" | awk '{print $1}')
  sd=$(echo   "$stats" | awk '{print $2}')
  vox=$(echo  "$stats" | awk '{print $3}')
  mm3=$(echo  "$stats" | awk '{print $4}')
  echo "$SUBJECT,$MODE,$roi,$metric,$mean,$sd,$vox,$mm3" >> "$OUTCSV"
}

for ROI in JHU_UF_L JHU_UF_R JHU_CgC_L JHU_CgC_R; do
  extract "$FA" $ROI FA
  extract "$MD" $ROI MD
  extract "$RD" $ROI RD
  extract "$AD" $ROI AD
done

echo "[DONE] Wrote: $OUTCSV"
echo "[HINT] Visual check: fsleyes $REF derivatives/roi/JHU_UF_L_mask_ref.nii.gz &"
echo "[INFO] Finished: $(date -Is)"
