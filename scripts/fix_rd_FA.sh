cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/TBSS_GROUP

for d in RD L1 MD; do
    for f in $d/*_FA_FA.nii.gz; do
        new=$(echo "$f" | sed 's/_FA_FA/_FA/')
        mv "$f" "$new"
    done
done
