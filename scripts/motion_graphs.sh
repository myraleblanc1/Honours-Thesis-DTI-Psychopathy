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
# /.../data/processed/<subj>/motion_plot.png
PROCESSED_BASE="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/processed"

# Pattern inside each subject folder where motion files live
# Adjust if needed, for example:
#   MOTION_GLOB="motion/*.txt"
#   MOTION_GLOB="motion/mc*.par"
MOTION_GLOB="motion/*.par"

# Labels for the six motion parameters
MOTION_LABELS="x,y,z,pitch,yaw,roll"

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
        tmpfile=$(mktemp)
        awk '{print $2, $3, $4, $5, $6, $7}' "$mf" > "$tmpfile"

        # Output image
        out_png="$outdir/motion_qc.png"

        echo "   -> Writing plot to: $out_png"

        fsl_tsplot \
            -i "$tmpfile" \
            -a "$MOTION_LABELS" \
            -t "$subj motion parameters" \
            -u 1 \
            -w 1200 -h 800 \
            -o "$out_png"

        # Clean up temp file
        rm -f "$tmpfile"
    done

    echo "   Finished subject: $subj"
    echo "-----------------------------------------"
done
