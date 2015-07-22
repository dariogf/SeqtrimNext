#!/usr/bin/env bash

# Sort two big illumina files corresponding to paired-end experiment and then join common sequences on different files. Sequences not in common goes to a separate file.

# cat $1 | awk '{split($0, a, " "); n++; if (n%1==0){printf("%s\t",a[1]);}; printf("%s",$0); if(n%4==0) { printf("\n");} else { printf("\t");} }'
# 
# exit

if [ "$#" < 4 ]; 
then
    echo ""
	echo "Use: $0 file1.fastq file2.fastq base_output_name tmp_dir"
    echo ""
	exit
fi

base_name=$3

if [[ -z "$base_name" ]]; then
    echo "$base_name doesn't exists"
    exit -1
fi

tmp_dir=$4

if [[ -z "$4" ]]; then
    tmp_dir=`pwd`
fi

if [[ ! -e "$tmp_dir" ]]; then
    echo "Tmp dir: $4 doesn't exists"
    exit -1
fi

echo "Using TMPDIR $tmp_dir"

f1_path=$1
f2_path=$2

f1_name=`basename $1`
f2_name=`basename $2`

f1_tmp="$tmp_dir/${f1_name}"
f2_tmp="$tmp_dir/${f2_name}"

common_names="$tmp_dir/comm.names"

only_in_1="$tmp_dir/only_in_1.txt"
only_in_2="$tmp_dir/only_in_2.txt"
in_both="$tmp_dir/in_both.txt"


echo "Starting sorting"

if [[ ! -e "$f1_tmp.sorted" ]]; then
    echo "Sorting $f1_name"
    cat $f1_path | awk '{split($0, a, " "); sub(/\/1$/,"\t", a[1]); n++; if (n%4==1){printf("%s",a[1]);}; printf("%s",$0); if(n%4==0) { printf("\n");} else { printf("\t");} }' | sort -T $tmp_dir -k1,1 -t $'\t' > $f1_tmp.sorted &

fi

if [[ ! -e "$f2_tmp.sorted" ]]; then
    echo "Sorting $f2_name"
    cat $f2_path | awk '{split($0, a, " "); sub(/\/2$/,"\t", a[1]); n++; if (n%4==1){printf("%s",a[1]);}; printf("%s",$0); if(n%4==0) { printf("\n");} else { printf("\t");} }' | sort -T $tmp_dir -k1,1 -t $'\t' > $f2_tmp.sorted &
fi
wait

echo "Starting name extraction"
if [[ ! -e "$f1_tmp.names" ]]; then
    echo "Extracting names from $f1_tmp.sorted"
    # cat $1.sorted | cut -f1 | sed 's/\(.*\)\/1$/\1/' > $1.names &
    cat $f1_tmp.sorted | cut -f1  > $f1_tmp.names &
fi
if [[ ! -e "$f2_tmp.names" ]]; then
    echo "Extracting names from $f2_tmp.sorted"
    cat $f2_tmp.sorted | cut -f1  > $f2_tmp.names &
fi
wait

echo "Starting names comparison"
if [[ ! -e "$common_names" ]]; then
    echo "Making comm file"
    # diff $1.names $2.names > names.diff
    comm $f1_tmp.names $f2_tmp.names > $common_names
fi

echo "Starting names extraction"
# grep '^>' names.diff | cut -d ' ' -f2 | awk '{ printf("%s/2\n",$0) }' > only_in_2.txt &
# grep '^<' names.diff | cut -d ' ' -f2 | awk '{ printf("%s/1\n",$0) }' > only_in_1.txt &

grep -P '^[^\t]' $common_names > $only_in_1 &
grep -P '^\t[^\t]' $common_names |tr -d "\t" > $only_in_2 &
grep -P '^\t\t[^\t]' $common_names |tr -d "\t" > $in_both &
wait

echo "Num seqs only in 1) $f1_name"
wc -l $only_in_1

echo "Num seqs only in 2) $f2_name"
wc -l $only_in_2

echo "Num seqs in both $f1_name and $f2_name"
wc -l $in_both

echo "Starting extracting seqs"
join -t $'\t' -1 1 -2 1 $only_in_1 $f1_tmp.sorted |cut -f 2,3,4,5| tr "\t" "\n" > ${base_name}_normal1.fastq &
join -t $'\t' -1 1 -2 1 $only_in_2 $f2_tmp.sorted |cut -f 2,3,4,5| tr "\t" "\n" > ${base_name}_normal2.fastq &

join -t $'\t' -1 1 -2 1 $in_both $f1_tmp.sorted  |cut -f 2,3,4,5| tr "\t" "\n" > ${base_name}_paired1.fastq &
join -t $'\t' -1 1 -2 1 $in_both $f2_tmp.sorted  |cut -f 2,3,4,5| tr "\t" "\n" > ${base_name}_paired2.fastq &
wait

rm $f1_tmp.names
rm $f2_tmp.names

rm $f1_tmp.sorted
rm $f2_tmp.sorted

rm $only_in_2
rm $only_in_1
rm $in_both

rm $common_names