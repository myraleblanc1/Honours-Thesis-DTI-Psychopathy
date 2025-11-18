#!/bin/bash
set -euo pipefail

#--------------------------------------------------
# CONFIGURATION
#--------------------------------------------------
BASE="/run/user/1002/gvfs/smb-share:server=cortex,share=mrn-data-archive/tescoke_20696/AUTO_ANALYSIS/triotim"
DEST="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw"
CSV="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/scripts/fsl/id_map.csv"

mkdir -p "$DEST"

#--------------------------------------------------
# MAIN LOOP
#--------------------------------------------------
tail -n +2 "$CSV" | while IFS=, read -r subj _; do
    echo ">>> Processing $subj"

    # Find all matching DTI stats directories using shell globs (GVFS-safe)
    matches=( "$BASE/$subj"/Study*/analysis/dti_*/dirall/motion)

    # Check if anything matched
    if [[ ! -d "${matches[0]}" ]]; then
        echo "    !! No analysis/dti folder found for $subj"
        echo "---------------------------------------"
        continue
    fi

    # Iterate over matches
    for dti in "${matches[@]}"; do
        echo " Found: $dti"
        outdir="$DEST/$subj"
        mkdir -p "$outdir"

        echo "Copying motion folder for $subj"
	cp -rP "$dti" "$outdir/"
        done
    done

    echo "    Copied to $DEST/$subj"
    echo " Finished processing $subj"
    echo "---------------------------------------"
done
