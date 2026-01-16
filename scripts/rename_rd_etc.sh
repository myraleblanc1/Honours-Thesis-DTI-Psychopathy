cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy/TBSS_GROUP/origdata

for fa in *.nii.gz; do
    # only act on FA files (no suffix)
    if [[ "$fa" != *_RD.nii.gz && "$fa" != *_L1.nii.gz && "$fa" != *_MD.nii.gz ]]; then
        subj=$(basename "$fa" .nii.gz)

        for metric in RD L1 MD; do
            if [[ -f "${subj}_${metric}.nii.gz" ]]; then
                ln -sf "${subj}_${metric}.nii.gz" "${subj}_FA_${metric}.nii.gz"
            fi
        done
    fi
done
