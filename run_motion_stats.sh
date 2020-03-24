#!/bin/sh
#SBATCH --partition=long
#SBATCH --time=2-
#SBATCH --mail-type=ALL
#SBATCH --job-name=MotionStats
#SBATCH --output=motion_stats_slurm_allsubs.out

module load Python/Anaconda3


# Written by PO
##last edited on 3/23/20
##################
##################

# Usage:
# option 1: use this to test
# $ sh scriptname.sh
# option 2: on an interactive server, do the following:
# $ cd /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats
# $ srun --pty --x11 -N 1 --mem=2000 bash
# $ sh scriptname.sh

# option 3: on a batch server (is faster and don't need to stay connected, but don't see the output immediately)
# recommended if running more than 1 or 2 subjects
# $ cd /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats
# $ sbatch scriptname.sh
#(the last command submits this job to the cluster)

##################
##################
# set environment (only if not in your bash script already)
# . /gpfs/milgram/apps/hpc.rhel7/software/FSL/6.0.0-centos7_64/etc/fslconf/fsl.sh
#module load OpenBLAS/0.2.18-GCC-5.4.0-2.26-LAPACK-3.6.1
#load an older version of python for the script that deletes 8 rows of motion regressors

##################
##################
# Specify subjectlist
##################
##################

#subjectlist updated by PO on 10/8/19 based on SC yoking google sheet


#subjects=("A204"	"A210"	"A211"	"A216"	"A222"	"A242"	"A247"	"A248"	"A253"	"A258"	"A260"	"A261"	"A262"	"A266"	"A281"	"A284"	"A285"	"A286"	"A288"	"A291"	"A294"	"A328"	"A348"	"A363"	"A374"	"A401"	"A415"	"A417"	"A425"	"A429"	"A440"	"A444"	"A445"	"A480"	"A526"	"A532"	"A548"	"A553"	"A555"	"A556"	"A559"	"A560"	"A563"	"A583"	"A584"	"A585"	"A592"	"A597"	"A598"	"A600"	"A603"	"A605"	"A609" "A611"	"A613"	"A616"	"A617"	"A618"	"A619"	"A620"	"A621"	"A622"	"A625"	"A629"	"A631"	"A632"	"A635"	"A637"	"A638"	"A639"	"A640"	"A641"	"A642"	"A643"	"A646"	"A647"	"A648"	"A649"	"A650"	"A651"	"A653"	"A656"	"A659"	"A660"	"A661"	"A663"	"A664"	"A665"	"A666"	"A668"	"A670"	"A673 "	"A677"	"A680"	"A686"	"A688"	"A690"	"A692"	"A695"	"A699"	"A707"	"A708"	"A715"	"A717"	"A721"	"A723"	"A724"	"A726"	"A729"	"A733"	"A741"	"A749"	"A996")

subjects=("A216")

#NOT YET PROCESSED subs: "A200"

# done with these subs:

#use this to specify subject in the commandline right after the script name (example: $ sh 1_create...sh A200)
#subjects=$1

block=("sc1part1" "sc1part2" "sc2part1" "sc2part2" "erpart1" "erpart2" "erpart3" "erpart4" "erpart5" "restinscapes") #select which scer runs you'd like to run this on. Takes ~10 minutes per run
#block=("sc2part2")
ScriptDir="/gpfs/milgram/project/gee_dylan/candlab/scripts/scer/motion_stats"
num_delete_vol=8
MotionScriptDir="/gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/task/remove_first_volumes"



for sub in "${subjects[@]}"; do

  datadir="/gpfs/milgram/project/gee_dylan/candlab/data/mri/hcp_pipeline_preproc/scer/sub-"$sub"/MNINonLinear/Results"
  rawdatadir="/gpfs/milgram/project/gee_dylan/candlab/data/mri/bids_recon/scer/sub-"$sub"/ses-scerV1/func"
  outdir="/gpfs/milgram/project/gee_dylan/candlab/analyses/scer_motion"

  #check if full subject output files already exist. If so, remove them to start brand new
  if [[ -e "$datadir"/Motionstats_summary_allruns.csv ]]; then
    rm "$datadir"/Motionstats_summary_allruns.csv
  fi
  if [[ -e "$outdir"/"$sub"_motionstats_summary.csv ]]; then
    rm "$outdir"/"$sub"_motionstats_summary.csv
  fi

  for run in "${block[@]}"; do
    ##################
    #Create output files
    ##################

    #check if output files already exist. If so, remove them
    if [[ -e "$datadir"/ses-scerV1_task-"$run"_bold/Motionstats_summary.csv ]]; then
      echo "
      **********
      ** Motion stats run output files exist for "$sub" "$run".
      ** Removing existing files from MNINonLinear/Results/[RUNS] and analyses/scer_motion
      **********"
      rm "$datadir"/ses-scerV1_task-"$run"_bold/Motionstats_summary.csv
    fi
  done

  for run in "${block[@]}"; do
    #Make a file with headings for motion stats summary (to know which value is what)
    #if file with all subjects already exists, skip this step of making headings
    if [ "$sub" != "${subjects[@]:0:1}" ] && [[ -e /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv ]]; then
      echo " "
    else
      #tabs and new lines depend on the run number
      if [ "$run" == "${block[@]:0:1}" ]; then
        #block=("sc1part1" "sc1part2" "sc2part1" "sc2part2")
        printf "\t record_id \t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      elif [[ "$run" == "${block[${#block[@]}-1]}" ]]; then #if it is the last one in the "block array"
        printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run" \n" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      else
        printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      fi
    fi
  done

  for run in "${block[@]}"; do

    #Now make individual files with headings for motion stats summary (to know which value is what)
    #print a headings file for each subject and run and put it in the MNI/Nonlinear/Results folder for each run
    printf "\t record_id \t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"\n" >> "$datadir"/ses-scerV1_task-"$run"_bold/Motionstats_summary.csv

    if [ "$run" == "${block[@]:0:1}" ]; then
      #block=("sc1part1" "sc1part2" "sc2part1" "sc2part2")
      printf "\t record_id \t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t record_id \t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> "$outdir"/"$sub"_motionstats_summary.csv
    elif [[ "$run" == "${block[${#block[@]}-1]}" ]]; then #if it is the last one in the "block array"
      printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"\n" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"\n" >> "$outdir"/"$sub"_motionstats_summary.csv
    else
      printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t relmean_motion_"$run" \t absmean_motion_"$run" \t fdmean_motion_"$run" \t fdover2_motion_"$run" \t fdover5_motion_"$run" \t fdstdev_motion_"$run" \t fdrangelow_motion_"$run" \t fdrangehigh_motion_"$run" \t fdnumoutliers_motion_"$run" \t fdpercoutliers_motion_"$run" \t outliersthresh_motion_"$run"" >> "$outdir"/"$sub"_motionstats_summary.csv
    fi
  done

  for run in "${block[@]}"; do


#######################
## FSL motion outliers
#######################
## Note: subject motion (or at least having those EVs in the model) affects
# the high-pass filter cutoff so we need to run fsl_motion_outliers first
## using framewise displacement (FD) and a set threshold of .2mm for all subjects



    #first rename Movement_FD to _8dv (if already exists) to avoid confusion later
    if [[ -f "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata.txt ]]; then
      mv "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata.txt "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata_8dv.txt
      mv "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_plot_rawdata.png "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_plot_rawdata_8dv.png
    fi

    ## check if outliers file exists first, if it already exists, do not want to overwrite. If it doesn't exist, proceed with script
    if [[ -f "$datadir"/ses-scerV1_task-"$run"_bold/Confound_EVs_FDbxpltoutliers_MovReg_8dv_rawdata.txt && -f "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata_8dv.txt ]]; then
      echo "
	     ##################################
	      WARNING: Counfound EVs file with boxplot outliers already exists. FSL motion outliers will end for this run.
	      If you need to re-run this subject, please delete/rename existing outliers and combined confound
	      EVs files in the subject's HCP pipelines dir
	     ##################################
"
		else

      echo "
    ***************************************************
    ** Starting fsl motion outliers for "$sub" "$run"**
    ***************************************************

  "

## need to remove first 8 timepoints in the raw data file first (see /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/task/remove_first_volumes/1_RmFirstVols_4D_and_MovReg.sh for more info on how this works)

			if [ -e "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz ]; then

				echo "
	*skipping fslroi since raw data 8dv exists for "$sub" "$run""


      elif [[ "$run" == "sc"* ]]; then
				echo "
	**running fslroi to remove first $num_delete_vol vols from RAW SC data**
		"
        fslroi "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold.nii.gz "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 366


      elif [[ "$run" == "er"* ]]; then
        echo "
  **running fslroi to remove first $num_delete_vol vols from RAW ER data**
    "
        fslroi "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold.nii.gz "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 401


      elif [[ "$run" == "rest"* ]]; then
        echo "
  **running fslroi to remove first $num_delete_vol vols from RAW REST data**
    "
        fslroi "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold.nii.gz "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 532
			fi

#also run fslroi on the preprocessed data if doesn't exist yet
      if [ -e "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz ]; then

        echo "
  *skipping fslroi since preproc data 8dv exists for "$sub" "$run""
      elif [[ "$run" == "sc"* ]]; then
        echo "
  **running fslroi to remove first $num_delete_vol vols from preprocessed SC data**
    "
        fslroi "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold.nii.gz "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 366
      elif [[ "$run" == "er"* ]]; then
        echo "
  **running fslroi to remove first $num_delete_vol vols from preprocessed ER data**
    "
        fslroi "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold.nii.gz "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 401
      elif [[ "$run" == "rest"* ]]; then
        echo "
  **running fslroi to remove first $num_delete_vol vols from preprocessed REST data**
    "
        fslroi "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold.nii.gz "$datadir"/ses-scerV1_task-"$run"_bold/ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz $num_delete_vol 532
      fi



## the command below runs fsl motion outliers on the RAW (unpreprocessed) data and puts the output files in the PREPROCESSED folder (since that is where all other motion data lives)
		echo "
	**running fsl motion outliers now: using FD with boxplot definition of outliers **
"

		fsl_motion_outliers -i "$rawdatadir"/sub-"$sub"_ses-scerV1_task-"$run"_bold_"$num_delete_vol"dv.nii.gz -o "$datadir"/ses-scerV1_task-"$run"_bold/Motion_Outliers_FDbxpltoutliers_rawdata.txt -s "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata_8dv.txt -p "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_plot_rawdata_8dv -v --fd  >> "$datadir"/ses-scerV1_task-"$run"_bold/"$sub"_"$run"_outliers.txt

#if doesn't already exist, cut out first 8 rows of motion txt files
    if [ -e "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_8dv.txt ]; then
      echo "
      "
    else
      python "$MotionScriptDir"/ShiftMovementReg.py  -m "$datadir"/ses-scerV1_task-"$run"_bold/Movement_Regressors.txt -dv $num_delete_vol
    fi


## concatenate outliers file with the existing confound ev file
## check if outliers file exists first, if it doesn't exist, that means that there were no outlier timepoints found
		echo "
	**concatenating output files to make confound file**
"
			#check that movement FD rawdata file was created (i.e., whether fsl_motion_outliers ran correctly)
			if [ -e "$datadir"/ses-scerV1_task-"$run"_bold/Movement_FD_rawdata_8dv.txt ]; then

				if [ -e "$datadir"/ses-scerV1_task-"$run"_bold/Motion_Outliers_FDbxpltoutliers_rawdata.txt ]; then
					paste "$datadir"/ses-scerV1_task-"$run"_bold/Motion_Outliers_FDbxpltoutliers_rawdata.txt "$datadir"/ses-scerV1_task-"$run"_bold/Movement_Regressors_8dv.txt >> "$datadir"/ses-scerV1_task-"$run"_bold/Confound_EVs_FDbxpltoutliers_MovReg_8dv_rawdata.txt
				else
					cp "$datadir"/ses-scerV1_task-"$run"_bold/Movement_Regressors_8dv.txt "$datadir"/ses-scerV1_task-"$run"_bold/Confound_EVs_FDbxpltoutliers_MovReg_8dv_rawdata.txt
				fi

			else
				echo "### ERROR: FD Movement File does not exist - check output above###"
      fi
    fi

#---------------------
#code below pulled from movementstats.sh
#written by Sadie Zacharek
#---------------------
  	movementDir2=""$datadir"/ses-scerV1_task-"$run"_bold"

  	#touch /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/allsubjects_motionstats_summary.csv

    echo "
  **********
  ** Starting movement stats extraction for "$sub" "$run"
  **********"


#########
#########
#########
## HERE NEED TO EDIT STARTING BELOW TO REMOVE THE FIRST 8 VOLUMES and not just take the pre-calculated mean (e.g. relative RMS mean from HCP preproc)
#########
#########
#########

#Relative mean: zero out the 9th row (row #8 if counting in python) (because motion is relative to the previous timepoint)
     if [ -e $movementDir2/Movement_RelativeRMS.txt ]; then
       RelFile="$movementDir2/Movement_RelativeRMS.txt"

       python "$MotionScriptDir"/ShiftMovementReg.py  -m $RelFile -dv $num_delete_vol

       RelMeanFile="$movementDir2/Movement_RelativeRMS_8dv_mean.txt"

       while read line; do
         relmean2=$line
       done < $RelMeanFile


     else
       echo "no relative mean file for subject $sub "$run""
       relmean2=' '
     fi




	#Absolute mean: don't zero out the 9th row (because motion is relative to the absolute zero- the initial volume)
    if [ -e $movementDir2/Movement_AbsoluteRMS.txt ]; then
      AbsFile="$movementDir2/Movement_AbsoluteRMS.txt"

      #use python ShiftMovementReg script to remove 8 rows and save new 8dv mean file
      python "$MotionScriptDir"/ShiftMovementReg.py  -m $AbsFile -dv $num_delete_vol

      #now get the mean from the file created in python script run above
      AbsMeanFile="$movementDir2/Movement_AbsoluteRMS_8dv_mean.txt"
      while read line; do
        absmean2=$line
      done < $AbsMeanFile

    else
      echo "no absolute mean file for subject $sub "$run""
      absmean2=' '
    fi


	#FD mean (this file already had 8dv, so can just proceed as normal)
		if [ -e $movementDir2/Movement_FD_rawdata_8dv.txt ]; then
			FDFile2="$movementDir2/Movement_FD_rawdata_8dv.txt"
			over2Point2=0
			over2Point5=0
			runningsum=0
			#fdmax2=0
			while read line; do
				runningsum=`echo $runningsum+$line | bc -l`
				if (( $(echo "$line > 0.2" | bc -l) )); then
					over2Point2=$[over2Point2+1]
					if (( $(echo "$line > 0.5" | bc -l) )); then
						over2Point5=$[over2Point5+1]
					fi
				fi
				#if (( $(echo "$line > $fdmax2" | bc -l) )); then
				#	fdmax2=$line
				#fi
			done < $FDFile2
      #now get the percent over .2 or .5
      if [[ "$run" == "sc"* ]]; then
    		fdmean2=`echo "$runningsum/366" | bc -l`
    		percentfd2Over2=`echo "$over2Point2/3.66" | bc -l` #move decimal point so we don't need to then multiply by 100
    		percentfd2Over5=`echo "$over2Point5/3.66" | bc -l`

    		FDFile2="$movementDir2/Movement_FD_rawdata_8dv.txt"
    		differencesum=0
    		while read line; do
    			difference=`echo $line-$fdmean2 | bc -l`
    			squareabs=`echo $difference*$difference | bc -l`
    			differencesum=`echo $squareabs+$differencesum | bc -l`
    		done < $FDFile2
    		totaldev=`echo "$differencesum/366" | bc -l`
    		stdev2=`echo "sqrt ( $totaldev )" | bc -l`
      elif [[ "$run" == "er"* ]]; then
    		fdmean2=`echo "$runningsum/401" | bc -l`
    		percentfd2Over2=`echo "$over2Point2/4.01" | bc -l` #move decimal point so we don't need to then multiply by 100
    		percentfd2Over5=`echo "$over2Point5/4.01" | bc -l`

    		FDFile2="$movementDir2/Movement_FD_rawdata_8dv.txt"
    		differencesum=0
    		while read line; do
    			difference=`echo $line-$fdmean2 | bc -l`
    			squareabs=`echo $difference*$difference | bc -l`
    			differencesum=`echo $squareabs+$differencesum | bc -l`
    		done < $FDFile2
    		totaldev=`echo "$differencesum/401" | bc -l`
    		stdev2=`echo "sqrt ( $totaldev )" | bc -l`
      elif [[ "$run" == "rest"* ]]; then
    		fdmean2=`echo "$runningsum/532" | bc -l`
    		percentfd2Over2=`echo "$over2Point2/5.32" | bc -l` #move decimal point so we don't need to then multiply by 100
    		percentfd2Over5=`echo "$over2Point5/5.32" | bc -l`

    		FDFile2="$movementDir2/Movement_FD_rawdata_8dv.txt"
    		differencesum=0
    		while read line; do
    			difference=`echo $line-$fdmean2 | bc -l`
    			squareabs=`echo $difference*$difference | bc -l`
    			differencesum=`echo $squareabs+$differencesum | bc -l`
    		done < $FDFile2
    		totaldev=`echo "$differencesum/532" | bc -l`
    		stdev2=`echo "sqrt ( $totaldev )" | bc -l`
      elif [[ "$run" == "shapes"* ]]; then
    		fdmean2=`echo "$runningsum/520" | bc -l`
    		percentfd2Over2=`echo "$over2Point2/5.20" | bc -l` #move decimal point so we don't need to then multiply by 100
    		percentfd2Over5=`echo "$over2Point5/5.20" | bc -l`

    		FDFile2="$movementDir2/Movement_FD_rawdata_8dv.txt"
    		differencesum=0
    		while read line; do
    			difference=`echo $line-$fdmean2 | bc -l`
    			squareabs=`echo $difference*$difference | bc -l`
    			differencesum=`echo $squareabs+$differencesum | bc -l`
    		done < $FDFile
    		totaldev=`echo "$differencesum/520" | bc -l`
    		stdev2=`echo "sqrt ( $totaldev )" | bc -l`
      fi
		else
			echo "no fd motion file for subject $sub "$run""
			percentfd2Over2=' '
			percentfd2Over5=' '
			fdmean2=' '
			#fdmax2=' '
			stdev2=' '
		fi

    #		movementDir2="$datadir"/ses-scerV1_task-"$run"_bold/

    if [ -e $movementDir2/"$sub"_"$run"_outliers.txt ]; then #cannot make this .txt because some files end in .out
      filename="$(ls ""$movementDir2"/"$sub"_"$run"_outliers.txt")"
      findline="$(awk '/Range/{ ln = FNR } END  { print ln }' "$filename")"

      #checkfile2=$(sed -n '2p' < "$filename") #check if second line starts with mcf
      #checkfile3=$(sed -n '3p' < "$filename") #check if third line starts with mcf
      #echo "checkfile is "$checkfile""
      #if [[ $checkfile2 == "mcf"* ]]; then
      ValueRange=$(sed -n $findline'p' < "$filename") #print the forth line in the output folder
      IFS=" " read var1 var2 var3 var4 var5 var6 <<< $ValueRange #gives each value in 4th line a variable
      lowrange=$var5 #lowrange is the 5th variable on line 5. This is hard-coded so careful with re-running fsl_outliers
      highrange=$var6
      outliersline=$(( $findline + 1 ))
      NumOutliers=$(sed -n $outliersline'p' < "$filename")
      IFS=" " read var1 var2 var3 var4 var5 <<< $NumOutliers
      outliers=$var2
      threshold=$var5

      if [[ "$run" == "sc"* ]]; then
        percoutliers=`echo "$outliers/3.66" | bc -l`
      elif [[ "$run" == "er"* ]]; then
        percoutliers=`echo "$outliers/4.01" | bc -l`
      elif [[ "$run" == "rest"* ]]; then
        percoutliers=`echo "$outliers/5.32" | bc -l`
      elif [[ "$run" == "shapes"* ]]; then
        percoutliers=`echo "$outliers/5.20" | bc -l`
      else
        percoutliers=' '
      fi
      # elif [[ $checkfile3 == "mcf"* ]]; then
      #   ValueRange=$(sed -n '6p' < "$filename") #print the forth line in the output folder
      #   IFS=" " read var1 var2 var3 var4 var5 var6 <<< $ValueRange #gives each value in 4th line a variable
      #   lowrange=$var5 #lowrange is the 5th variable on line 5. This is hard-coded so careful with re-running fsl_outliers
      #   highrange=$var6
      #   NumOutliers=$(sed -n '7p' < "$filename")
      #   IFS=" " read var1 var2 var3 var4 var5 <<< $NumOutliers
      #   outliers=$var2
      #   threshold=$var5
      # else
  	  #   ValueRange=$(sed -n '4p' < "$filename") #print the forth line in the output folder
  	  #   IFS=" " read var1 var2 var3 var4 var5 var6 <<< $ValueRange #gives each value in 4th line a variable
  	  #   lowrange=$var5 #lowrange is the 5th variable on line 5. This is hard-coded so careful with re-running fsl_outliers
  	  #   highrange=$var6
  	  #   NumOutliers=$(sed -n '5p' < "$filename")
      #   IFS=" " read var1 var2 var3 var4 var5 <<< $NumOutliers
  	  #   outliers=$var2
  	  #   threshold=$var5
      #fi

    elif [ -e $movementDir2/"$sub"_"$run"_outliers.out ]; then
      filename="$(ls ""$movementDir2"/"$sub"_"$run"_outliers.out")"
      findline="$(awk '/Range/{ ln = FNR } END  { print ln }' "$filename")"

      #checkfile2=$(sed -n '2p' < "$filename") #check if second line starts with mcf
      #checkfile3=$(sed -n '3p' < "$filename") #check if third line starts with mcf
      #echo "checkfile is "$checkfile""
      #if [[ $checkfile2 == "mcf"* ]]; then
      ValueRange=$(sed -n $findline'p' < "$filename") #print the forth line in the output folder
      IFS=" " read var1 var2 var3 var4 var5 var6 <<< $ValueRange #gives each value in 4th line a variable
      lowrange=$var5 #lowrange is the 5th variable on line 5. This is hard-coded so careful with re-running fsl_outliers
      highrange=$var6
      outliersline=$(( $findline + 1 ))
      NumOutliers=$(sed -n $outliersline'p' < "$filename")
      IFS=" " read var1 var2 var3 var4 var5 <<< $NumOutliers
      outliers=$var2
      threshold=$var5

      if [[ "$run" == "sc"* ]]; then
        percoutliers=`echo "$outliers/3.66" | bc -l`
      elif [[ "$run" == "er"* ]]; then
        percoutliers=`echo "$outliers/4.01" | bc -l`
      elif [[ "$run" == "rest"* ]]; then
        percoutliers=`echo "$outliers/5.32" | bc -l`
      elif [[ "$run" == "shapes"* ]]; then
        percoutliers=`echo "$outliers/5.20" | bc -l`
      else
        percoutliers=' '
      fi


    else
      echo "no fd outliers file for subject $sub "$run""
      lowrange=' ' #lowrange is the 5th variable on line 5. This is hard-coded so careful with re-running fsl_outliers
      highrange=' '
      NumOutliers=' '
      outliers=' '
      percoutliers=' '
      threshold=' '
    fi




    echo "
      **********
      ** Writing motion stats files for "$sub" "$run"
      **********
    "
		#Write subject's info to csv

    #first write the run-level motion stats into subject's hcp pipelines difference

    printf "\t$sub \t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> "$datadir"/ses-scerV1_task-"$run"_bold/Motionstats_summary.csv



    if [[ "$run" == "${block[@]:0:1}" ]]; then
    #block=("sc1part1" "sc1part2" "sc2part1" "sc2part2")
		  printf "\t$sub \t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      printf "\t$sub \t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t$sub \t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> "$outdir"/"$sub"_motionstats_summary.csv
    elif [[ "$run" == "${block[${#block[@]}-1]}" ]]; then
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold \n" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold \n" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold \n" >> "$outdir"/"$sub"_motionstats_summary.csv
    else
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> "$datadir"/Motionstats_summary_allruns.csv
      printf "\t $relmean2 \t $absmean2 \t $fdmean2 \t $percentfd2Over2 \t $percentfd2Over5 \t $stdev2 \t $lowrange \t $highrange \t $outliers \t $percoutliers \t $threshold" >> "$outdir"/"$sub"_motionstats_summary.csv
    fi

    ###
    #Move files to appropriate folders
    ###

    cp /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/Allsubjects_movementstatistics.csv /gpfs/milgram/project/gee_dylan/candlab/analyses/scer_motion/allsubjects_motionstats_summary.csv
    chmod 775 -R /gpfs/milgram/project/gee_dylan/candlab/scripts/scer/mri/motion_stats/
    chmod 775 -R "$outdir"
    chmod 775 "$datadir"/ses-scerV1_task-"$run"_bold/Motionstats_summary.csv
    chmod 775 "$datadir"/Motionstats_summary_allruns.csv

    ###
    #use this to concatenate all subject data in this folder
    #paste -d "\n" "$outdir"/A*_motionstats_summary.csv >> "$outdir"/NEW_allsubjects_motionstats_summary.csv

  done
done
