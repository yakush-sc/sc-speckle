#!/bin/bash

TARGET_RUN=""              #this line was auto-generated from gen_binaries.sh
INPUT_TYPE=ref             #this line was auto-generated from gen_binaries.sh
BENCHMARKS=(400.perlbench) #this line was auto-generated from gen_binaries.sh
                           # this allows us to externally set the parameters this script will execute

export PATH=".:$PATH"

bench_count=0
base_dir=$PWD

mkdir -p ${base_dir}/output

StartDate=$(date)
echo "Started at $StartDate" | (tee ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "From /proc/cpuinfo"    | (tee -a ${base_dir}/output/report.txt)
cat /proc/cpuinfo            | (tee -a ${base_dir}/output/report.txt) 
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "From /proc/meminfo"    | (tee -a ${base_dir}/output/report.txt)
cat /proc/meminfo            | (tee -a ${base_dir}/output/report.txt) 
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "From /etc/*release* /etc/*version*" | (tee -a ${base_dir}/output/report.txt)
cat /etc/*release*           | (tee -a ${base_dir}/output/report.txt)
cat /etc/*version*           | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "uname -a:"             | (tee -a ${base_dir}/output/report.txt)
uname -a                     | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "hostname -I:"          | (tee -a ${base_dir}/output/report.txt)
hostname -I                  | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "SPEC is set to: $PWD"  | (tee -a ${base_dir}/output/report.txt) 
echo "TARGET_RUN: $TARGET_RUN" | (tee -a ${base_dir}/output/report.txt)
echo ""                        | (tee -a ${base_dir}/output/report.txt)
echo "mount -l:"             | (tee -a ${base_dir}/output/report.txt)
mount -l                     | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)

echo "Write speed:"          | (tee -a ${base_dir}/output/report.txt)
dd if=/dev/zero of=output/test-disk.tmp bs=64k count=128 oflag=direct  2>&1 | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo "Read speed:"           | (tee -a ${base_dir}/output/report.txt)
#sudo /sbin/sysctl -w vm.drop_caches=3
dd if=output/test-disk.tmp of=/dev/zero bs=64k count=128               2>&1 | (tee -a ${base_dir}/output/report.txt)
rm output/test-disk.tmp
echo ""                      | (tee -a ${base_dir}/output/report.txt)
echo ""                      | (tee -a ${base_dir}/output/report.txt)


echo "bench,time" > ${base_dir}/output/report.csv

dmesg             > ${base_dir}/output/dmesg.txt

for b in ${BENCHMARKS[@]}; do

   echo " -== ${b} ==-"  | (tee -a ${base_dir}/output/report.txt)

   cd ${base_dir}/${b}
   SHORT_EXE=${b##*.} # cut off the numbers ###.short_exe
   if [ $b == "483.xalancbmk" ]; then 
      SHORT_EXE=Xalan #WTF SPEC???
   fi
   
   # read the command file
   IFS=$'\n' read -d '' -r -a commands < ${base_dir}/commands/${b}.${INPUT_TYPE}.cmd

   # run each workload
   count=0
   total_elapsed=0
   for input in "${commands[@]}"; do

      if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files

         cmd="${TARGET_RUN} ${SHORT_EXE} ${input} > >(tee ${base_dir}/output/${SHORT_EXE}.${count}.out) 2> >(tee ${base_dir}/output/${SHORT_EXE}.${count}.err >&2)"
         echo "workload=[${cmd}]"

         start_time=$(date +%s.%6N)
         eval ${cmd}
         end_time=$(date +%s.%6N)

         elapsed=$(echo "scale=6; $end_time - $start_time" | bc)
         echo "Workload elapsed time ($bench_count:$count) = $elapsed seconds" | (tee -a ${base_dir}/output/report.txt)

         total_elapsed=$(echo $total_elapsed + $elapsed | bc)

         ((count++))
      fi
   done
   echo "Total elapsed time: $total_elapsed"    | (tee -a ${base_dir}/output/report.txt)
   echo ""                                      | (tee -a ${base_dir}/output/report.txt)
   echo "$b,$total_elapsed" >> ${base_dir}/output/report.csv

   ((bench_count++))
done

echo "Done!"
FinalDate=$(date)

StartDateFmt=$(date -u -d "$StartDate" +"%s")
FinalDateFmt=$(date -u -d "$FinalDate" +"%s")
ElapsedDate=( $(date -u -d "0 $FinalDateFmt sec - $StartDateFmt sec" +"%H:%M:%S") )

echo "Finished at $FinalDate; elapsed $ElapsedDate" | (tee -a ${base_dir}/output/report.txt)

echo ""
echo "Benchmark Times:"

cat ${base_dir}/output/report.txt
