#!/usr/bin/env bash
#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------
# USER PATHS — modify if needed
# ------------------------------------------------------
BASEDIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy"
RAW="${BASEDIR}/data/raw"
OUTDIR="${BASEDIR}/data/processed/roi_batch"
ATLAS="$FSLDIR/data/atlases/JHU/JHU-ICBM-labels-1mm.nii.gz"
FA_TMPL="$FSLDIR/data/standard/FMRIB58_FA_1mm.nii.gz"   # reference for native→MNI alignment

mkdir -p "$OUTDIR"/group_csv "$OUTDIR"/qc "$OUTDIR"/roi_masks
LOG="$OUTDIR/batch_extract_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -i "$LOG") 2>&1

echo "[INFO] Starting batch ROI extraction"
echo "[INFO] Raw folder: $RAW"
echo "[INFO] Output folder: $OUTDIR"

# ------------------------------------------------------
# FIXED LABEL INDICES (from your prereg + old script)
# ------------------------------------------------------
UF_L_IDX=48
UF_R_IDX=47
CgC_L_IDX=36
CgC_R_IDX=35

echo "[INFO] Using JHU Labels atlas indices:"
echo "[INFO] UF_L=$UF_L_IDX UF_R=$UF_R_IDX CgC_L=$CgC_L_IDX CgC_R=$CgC_R_IDX"

# ------------------------------------------------------
# OUTPUT CSV (group-level)
# ------------------------------------------------------
CSV="$OUTDIR/group_csv/roi_metrics_ALL_SUBJECTS.csv"
echo "subject,space,roi,metric,mean,sd,voxels,mm3" > "$CSV"

# ------------------------------------------------------
# Batch loop
# ------------------------------------------------------
for SUBJ in "$RAW"/* ; do
    [ -d "$SUBJ" ] || continue
    ID=$(basename "$SUBJ")
    echo "-------------------------"
    echo "[SUBJECT] $ID"
    mkdir -p "$OUTDIR/$ID"

    # detect FA files
    FA_STD=$(ls "$SUBJ"/tbdti_FA*.nii* 2>/dev/null || true)
    FA_NATIVE=$(ls "$SUBJ"/rdti_FA*.nii* 2>/dev/null || true)

    MODE=""
    REF=""
    FA=""
    MD=""
    RD=""
    AD=""

    # ---------------------------------------
    # STANDARD-SPACE INPUT (tbdti files)
    # ---------------------------------------
    if [ -n "$FA_STD" ]; then
        MODE="STANDARD"

        FA="$FA_STD"
        MD=$(ls "$SUBJ"/tbdti_MD*.nii* 2>/dev/null)
        RD=$(ls "$SUBJ"/tbdti_RD*.nii* 2>/dev/null)
        AD=$(ls "$SUBJ"/tbdti_L1*.nii* 2>/dev/null)
        REF="$FA"

        echo "[INFO] Using STANDARD-space files"

    # ---------------------------------------
    # NATIVE-SPACE INPUT (rdti files)
    # ---------------------------------------
    elif [ -n "$FA_NATIVE" ]; then
        MODE="NATIVE"

        echo "[INFO] Found native-space maps; registering to MNI…"
        mkdir -p "$OUTDIR/$ID/mni"

        flirt -in "$FA_NATIVE" -ref "$FA_TMPL" -omat "$OUTDIR/$ID/subj2MNI.mat" -dof 12 -cost corratio

        for metric in FA MD RD L1; do
            in=$(ls "$SUBJ"/rdti_${metric}*.nii* 2>/dev/null)
            out="$OUTDIR/$ID/mni/${metric}_MNI.nii.gz"
            flirt -in "$in" -ref "$FA_TMPL" -applyxfm -init "$OUTDIR/$ID/subj2MNI.mat" -out "$out"
        done

        FA="$OUTDIR/$ID/mni/FA_MNI.nii.gz"
        MD="$OUTDIR/$ID/mni/MD_MNI.nii.gz"
        RD="$OUTDIR/$ID/mni/RD_MNI.nii.gz"
        AD="$OUTDIR/$ID/mni/L1_MNI.nii.gz"
        REF="$FA"

        echo "[INFO] Finished affine registration."

    else
        echo "[ERROR] No valid DTI maps found for $ID"
        continue
    fi

    # ------------------------------------------------------
    # BUILD + RESAMPLE MASKS FOR THIS SUBJECT
    # ------------------------------------------------------
    ROISUBDIR="$OUTDIR/$ID/roi"
    mkdir -p "$ROISUBDIR"

    make_mask () {  # idx, name
        idx=$1
        name=$2

        fslmaths "$ATLAS" -thr "$idx" -uthr "$idx" -bin "$ROISUBDIR/${name}_mask_1mm.nii.gz"

        flirt -in "$ROISUBDIR/${name}_mask_1mm.nii.gz" \
              -ref "$REF" \
              -applyxfm -usesqform \
              -interp nearestneighbour \
              -out "$ROISUBDIR/${name}_mask_ref.nii.gz"
    }

    make_mask $UF_L_IDX JHU_UF_L
    make_mask $UF_R_IDX JHU_UF_R
    make_mask $CgC_L_IDX JHU_CgC_L
    make_mask $CgC_R_IDX JHU_CgC_R

    # ------------------------------------------------------
    # METRIC EXTRACTION
    # ------------------------------------------------------
    extract () { # img, roi_name, metric
        IMG="$1"
        ROI="$2"
        MET="$3"

        stats=$(fslstats "$IMG" -k "$ROISUBDIR/${ROI}_mask_ref.nii.gz" -M -S -V)
        echo "$ID,$MODE,$ROI,$MET,$(echo $stats | tr ' ' ',')" >> "$CSV"
    }

    for ROI in JHU_UF_L JHU_UF_R JHU_CgC_L JHU_CgC_R; do
        extract "$FA"  "$ROI" FA
        extract "$MD"  "$ROI" MD
        extract "$RD"  "$ROI" RD
        extract "$AD"  "$ROI" AD
    done

    # QC images
    slicer "$REF" "$ROISUBDIR/JHU_UF_L_mask_ref.nii.gz" -a "$OUTDIR/qc/${ID}_UF_L.png" || true
    slicer "$REF" "$ROISUBDIR/JHU_UF_R_mask_ref.nii.gz" -a "$OUTDIR/qc/${ID}_UF_R.png" || true
    slicer "$REF" "$ROISUBDIR/JHU_CgC_L_mask_ref.nii.gz" -a "$OUTDIR/qc/${ID}_CgC_L.png" || true
    slicer "$REF" "$ROISUBDIR/JHU_CgC_R_mask_ref.nii.gz" -a "$OUTDIR/qc/${ID}_CgC_R.png" || true

    echo "[DONE] Processed $ID"
done

echo "========================================"
echo "[FINISHED] Combined CSV saved to:"
echo "$CSV"
echo "QC images saved to: $OUTDIR/qc/"
echo "========================================"
