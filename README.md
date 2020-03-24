# candlab_scripts


Paola wrote a script in bash that will extract motion data that can be uploaded to REDCap Post Consent Tracking SC/ER motion exclusion:

the script is located in: /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/run_motion_stats.sh

This script deletes the first 8 volumes in the raw and preprocessed data, runs fsl_motion_outliers (if not completed yet), and compiles all motion stats in the following spreadsheets:

1. one file per subject per run located in: /gpfs/milgram/project/gee_dylan/candlab/data/mri/hcp_pipeline_preproc/scer/sub-[SUBID]/MNINonLinear/Results/[RUNNAME]/Motionstats_summary.csv
2. one file per subject (for all runs) located in: /gpfs/milgram/project/gee_dylan/candlab/data/mri/hcp_pipeline_preproc/scer/sub-[SUBID]/MNINonLinear/Results/Motionstats_summary_allruns.csv
3. one file per subject (for all runs; cloned from #2 above) located in: /gpfs/milgram/project/gee_dylan/candlab/analyses/scer_motion/[SUBID]_motionstats_summary.csv
4. one file with ALL subjects (NOTE: each subject will be appended to at the bottom each time the script is run- potentially ending up with duplicates) located in: /gpfs/milgram/project/gee_dylan/candlab/analyses/scer_motion/ allsubjects_motionstats_summary.csv
5. one file with ALL subjects (cloned from #4 above) in:  /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv

Either #4 or #5 then needs to be cleaned (i.e., check for missing fields, change scientific number format to decimals) and uploaded to REDCap using the data import tool. The exclusion fields should then auto-populate using built-in equations. 

Finally, the "SC/ER_motion_exclusion" query should be used to generate an up-to-date spreadsheet like the one attached. The [RUN] motion exclude?" fields are 0 for runs that do NOT need to be excluded and 1 for those that SHOULD be excluded.
