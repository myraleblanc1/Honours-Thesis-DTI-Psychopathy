#!/bin/bash
set -euo pipefail 
BASE="/run/user/1002/gvfs/smb-share:server=cortex,share=mrn-data-archive/tescoke_20696/AUTO_ANALYSIS/triotim"
DEST="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/data/raw"
CSV="/home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/scripts/fsl/id_map.csv"
mkdir -p "$DEST" 
tail -n +2 "$CSV" | while IFS=, read -r subj _; do 
 echo ">>> Processing $subj" 
 dti_paths="" 
 for analysis_dir in $(find "$BASE" -maxdepth 12 -type d -path "*/$subj/*/analysis*/dti*/tbss/stats" 2>/dev/null)
 do 
   if find "$analysis_dir" -maxdepth 2 -type d -iname "*dti*" | grep -q .; then 
     dti_found=$(find "$analysis_dir" -maxdepth 2 -type d -iname "*dti*" | head -n 1) 
     dti_paths+="$dti_found"$'\n' 
   fi 
 done  
 if [[ -z "$dti_paths" ]]; then 
   echo "    !! No analysis/dti folder found for $subj" 
   continue 
 fi 
 while IFS= read -r dti; do
   echo " Found: $dti" 
   outdir="$DEST/$subj" 
   mkdir -p "$outdir" 
   for file in "$dti"/all_FA.nii.gz "$dti"/mean_FA.nii.gz "$dti"/mean_FA_mask.nii.gz "$dti"/mean_FA_skeleton.nii.gz; do
       if [[ -f "$file" ]]; then 
           cp -P "$file" "$outdir"/ 
       else 
           echo "  Missing expected file: $(basename "$file") for $subj" 
       fi 
   done 
 done <<< "$dti_paths" 
 echo "    Copied to $DEST/$subj" 
echo " Finished processing $subj" 
echo "---------------------------------------" 
done

