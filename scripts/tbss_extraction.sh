#!/usr/bin/env bash
set -euo pipefail

TBSS_DIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/TBSS_GROUP"
STATS="$TBSS_DIR/stats"
ROIS="$TBSS_DIR/rois_skel"
OUT="$TBSS_DIR/outputs"

SUBJECTS="$TBSS_DIR/subject_order.txt"

METRICS=("FA" "RD" "L1" "MD")
ROIS_LIST=("UF_L_skel" "UF_R_skel" "DC_L_skel" "DC_R_skel")

OUTCSV="$OUT/tbss_roi_values.csv"
mkdir -p "$OUT"

echo "subject,metric,roi,value" > "$OUTCSV"

nsub=$(wc -l < "$SUBJECTS")

for ((i=0; i<nsub; i++)); do
    subj=$(sed -n "$((i+1))p" "$SUBJECTS")

    for metric in "${METRICS[@]}"; do
        img="$STATS/all_${metric}_skeletonised.nii.gz"

        # extract subject volume
        fslroi "$img" /tmp/tmp_subj.nii.gz "$i" 1

        for roi in "${ROIS_LIST[@]}"; do
            roi_mask="$ROIS/${roi}.nii.gz"

            val=$(fslstats /tmp/tmp_subj.nii.gz -k "$roi_mask" -M)

            echo "${subj},${metric},${roi},${val}" >> "$OUTCSV"
        done
    done
done

rm -f /tmp/tmp_subj.nii.gz

echo "[DONE] CSV written to $OUTCSV"
