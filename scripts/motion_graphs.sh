#!/bin/bash
set -euo pipefail

#--------------------------------
# CONFIGURATION
#--------------------------------

# CSV with subject IDs in the first column (header in first row)
CSV="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/scripts/fsl/id_map.csv"

# Where your raw data lives, expected structure:
# /.../data/raw/<subj>/motion/<motion_file>.par
MOTION_BASE="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw"

# Where you want processed outputs:
# /.../data/processed/<subj>/motion_qc_*.png
PROCESSED_BASE="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed"

# Pattern inside each subject folder where motion files live
# Adjust if needed, for example:
#   MOTION_GLOB="motion/*.txt"
#   MOTION_GLOB="motion/mc*.par"
MOTION_GLOB="motion/fvolume.txt"

# Labels for motion parameters
MOTION_LABELS_TRANS="x,y,z"
MOTION_LABELS_ROT="pitch,yaw,roll"

#--------------------------------
# MAIN LOOP
#--------------------------------

tail -n +2 "$CSV" | while IFS=, read -r subj _; do
    subj=$(echo "$subj" | xargs)   # trim spaces just in case
    if [[ -z "$subj" ]]; then
        continue
    fi

    echo ">>> Processing subject: $subj"

    # Find motion files for this subject
    motion_files=( "$MOTION_BASE/$subj"/$MOTION_GLOB )

    # Check if anything matched
    if [[ ! -f "${motion_files[0]:-}" ]]; then
        echo "   !! No motion file found for $subj in:"
        echo "      $MOTION_BASE/$subj/$MOTION_GLOB"
        echo "-----------------------------------------"
        continue
    fi

    # Subject specific processed directory
    outdir="$PROCESSED_BASE/$subj"
    mkdir -p "$outdir"

    # Loop over motion files (usually just one)
    for mf in "${motion_files[@]}"; do
        if [[ ! -f "$mf" ]]; then
            continue
        fi

        echo "   Found motion file: $mf"

        # Make a temp file with FIRST COLUMN REMOVED
        # Assuming your file looks like:  vol x y z pitch yaw roll  (7 columns)
        # tmpfile columns become: 1:x  2:y  3:z  4:pitch  5:yaw  6:roll
        tmpfile=$(mktemp)
        awk '{print $2, $3, $4, $5, $6, $7}' "$mf" > "$tmpfile"

        # Output images
        out_trans="$outdir/motion_qc_trans.png"
        out_rot="$outdir/motion_qc_rot.png"

        echo "   -> Removing any old plots:"
        rm -f "$out_trans" "$out_rot"

        echo "   -> Writing translation plot (x,y,z) to: $out_trans"
        fsl_tsplot \
            -i "$tmpfile" \
            --start 1 \
            -finish 3 \
            -a "$MOTION_LABELS_TRANS" \
            -t "$subj translation (x,y,z)" \
            -u 1 \
            -w 1200 -h 400 \
            -o "$out_trans"

        echo "   -> Writing rotation plot (pitch,yaw,roll) to: $out_rot"
        fsl_tsplot \
            -i "$tmpfile" \
            --start 4 \
            --finish 6 \
            -a "$MOTION_LABELS_ROT" \
            -t "$subj rotation (pitch,yaw,roll)" \
            -u 1 \
            -w 1200 -h 400 \
            -o "$out_rot"

        # Clean up temp file
        rm -f "$tmpfile"
    done

    echo "   Finished subject: $subj"
    echo "-----------------------------------------"
done
