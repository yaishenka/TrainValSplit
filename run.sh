#!/bin/bash

STRATISFIED=false

for argument in "$@"
do
	key=$(echo $argument | cut -f1 -d=)
	value=$(echo $argument | cut -f2 -d=) 

	case "$key" in
            --input)              INPUT=${value} ;;
            --train_ratio)    RATIO=${value} ;; 
            --stratisfied)    STRATISFIED=true ;;  
            --y_column)    COLUMN=${value} ;;     
            *)   
    esac  
done    

echo "input = $INPUT"
echo "train_ratio = $RATIO"
echo "stratisfied = $STRATISFIED"
echo "y_column = $COLUMN"

TRAIN_FILE="$INPUT.train"
VAL_FILE="$INPUT.val"
TMP_FILE="$INPUT.tmp"

rm -f $TRAIN_FILE
rm -f $TMP_FILE
rm -f $VAL_FILE

if [ "$STRATISFIED" == false ];
then
	gawk -v ratio=$RATIO -v train=$TRAIN_FILE -v val=$VAL_FILE '{
		if (NR == 1) {
			print > train
			print > val
		} else {
			if (rand() < ratio / 100) {
				print > train
			} else {
				print > val
			}
		}
		
	}' $INPUT
else 
	gawk -v column=$COLUMN -v tmp_file=$TMP_FILE '
		BEGIN {
			FPAT = "([^,]*)|(\"[^\"]+\"+)"
		} 
		{	
			if (NR == 1) {
				filedsCount = NF
				for (i = 1; i <= NF; i++) {				
					nameToIndex[$i] = i;
				}
			} else {
				if (NF == filedsCount) {
					if ($nameToIndex[column] in classes == 0) {
						classesCount += 1;
					}
					classes[$nameToIndex[column]]++;
				}
			}
		} END {
			print classesCount > tmp_file
			for (var in classes) {
				print var > tmp_file
				print classes[var] > tmp_file
			}

	}' $INPUT




	gawk -v column=$COLUMN -v tmp_file=$TMP_FILE -v ratio=$RATIO -v train=$TRAIN_FILE -v val=$VAL_FILE '
		BEGIN {
			FPAT = "([^,]*)|(\"[^\"]+\"+)"
			getline var < tmp_file
			for (i = 0; i < var; i++) {
				getline className < tmp_file;
				getline classCount < tmp_file;
				classesCount[className] = classCount
			}
		} {
			if (NR == 1) {
				filedsCount = NF
				for (i = 1; i <= NF; i++) {				
					nameToIndex[$i] = i;
				}
				print > train
				print > val
			} else {
				if (NF == filedsCount) {
					classesInTrain[$nameToIndex[column]]++;

					if (classesInTrain[$nameToIndex[column]] < classesCount[$nameToIndex[column]] * ratio / 100) {
						print > train
					} else {
						print > val
					}
				}
			}

		} END {
			for (var in classesInTrain) {
				print var, classesInTrain[var]
			}
		}
	' $INPUT

	rm -f $TMP_FILE
fi

echo "Val dataset in $VAL_FILE"
echo "Train dataset in $TRAIN_FILE"