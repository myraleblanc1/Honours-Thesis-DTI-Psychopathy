cd /home/mleblanc/DTI_Psychopathy/Honours-Thesis-DTI-Psychopathy
SUBJ=M87100419
cd data/raw/$SUBJ

applywarp
--in=rdti_MD.nii.gz
--ref=target.nii.gz
--warp=rdti_FA_FA_to_target_warp.nii.gz
--out=rdti_MD_to_target.nii.gz
--interp=spline
