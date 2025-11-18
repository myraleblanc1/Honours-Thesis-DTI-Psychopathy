#motion graphs creation
#!/bin/bash
set -euo pipefail

#-------------------------------
# CONFIGURATION
#-------------------------------
CSV="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/scripts/fsl/id_map.csv"
BASE="/run/user/1002/gvfs/smb-share:server=cortex,share=mrn-data-archive/tescoke_20696/AUTO_ANALYSIS/triotim"
OUTDIR="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/qc/motion_plots"

# Adjust this pattern to point to your motion parameter files
# Example guesses (you'll tweak this):
#   mc/prefiltered_func_data_mcf.par
#   or something like */motion.par
MOTION_GLOB="Study*/analysis/dti_*/dirall/*/mc/prefiltered_func_data_mcf.par"

mkdir -p "$OUTDIR"

#-------------------------------
# MAIN LOOP
#-------------------------------
tail -n +2 "$CSV" | while IFS=, read -r subj _; do
    echo ">>> Processing $subj"

    # Find motion files for this subject
    motion_files=( "$BASE/$subj"/$MOTION_GLOB )

    # If nothing matched, skip
    if [[ ! -f "${motion_files[0]:-}" ]]; then
        echo "    !! No motion file found for $subj"
        echo "---------------------------------------"
        continue
    fi

    for mf in "${motion_files[@]}"; do
        echo "    Found motion file: $mf"

        # Build output name
        fname=$(basename "$mf")
        stem="${fname%.*}"  # strip extension
        png="$OUTDIR/${subj}_${stem}_motion_qc.png"

        echo "    -> Plotting to: $png"

        fsl_tsplot \
          -i "$mf" \
          -a x,y,z,pitch,yaw,roll \
          -t "${subj} ${stem} motion" \
          -u 1 \
          -w 1200 -h 800 \
          -o "$png"
    done

    echo " Finished $subj"
    echo "---------------------------------------"
done

