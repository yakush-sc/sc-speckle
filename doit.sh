
#!/bin/bash
# (C) Syntacore 2022
# Cross-compile SPEC CPU 2006 on host and run remotely on fpga

export PATH="$PATH:/home/yakush-sc/dev/riscv-rel/riscv-gcc-11.1.0-g477443e-211230T1056/bin"
#export PATH="$PATH:/home/yakush-sc/dev/sc-ide/out/riscv-gcc-10.1.0-gaeccc7a-220110T2139/bin"

export SPEC_DIR=/home/yakush-sc/dev/cpu2006/

export INPUT_TYPE=ref
#471.omnetpp 483.xalancbmk 473.astar 456.hmmer 403.gcc 400.perlbench 429.mcf 401.bzip2 445.gobmk 458.sjeng 462.libquantum 464.h264ref
export BENCHMARKS_STR="483.xalancbmk 473.astar 456.hmmer 403.gcc 400.perlbench 429.mcf 401.bzip2 445.gobmk 458.sjeng 462.libquantum 464.h264ref 471.omnetpp"

# compile & run remotely
OUT_DIR_NAME=riscv-spec-$INPUT_TYPE
BUILD_DIR=$PWD/build

CC=riscv64-unknown-linux-gnu-gcc
CXX=riscv64-unknown-linux-gnu-g++

# Cleanup folders
rm -rf ./$OUT_DIR_NAME/ $BUILD_DIR
mkdir -p $OUT_DIR_NAME $BUILD_DIR

LOG=$BUILD_DIR/compile-report.txt

StartDate=$(date)

echo "Started at $StartDate" | (tee $LOG)
echo ""   | (tee -a $LOG)
echo "CC" | (tee -a $LOG)
which $CC | (tee -a $LOG)
$CC -v 2>&1 | (tee -a $LOG)
#echo | $CC  -x c   -march=rv64gc -mabi=lp64d -E -Wp,-v - | (tee -a $LOG)
echo ""   | (tee -a $LOG)
echo "CXX" | (tee -a $LOG)
which $CXX | (tee -a $LOG)
$CXX -v 2>&1 | (tee -a $LOG)
#echo | $CXX -x c++ -march=rv64gc -mabi=lp64d -E -Wp,-v - | (tee -a $LOG)
echo ""   | (tee -a $LOG)

./gen_binaries.sh --compile --copy 2>&1 | (tee -a $LOG)

FinalDate=$(date)

StartDateFmt=$(date -u -d "$StartDate" +"%s")
FinalDateFmt=$(date -u -d "$FinalDate" +"%s")
ElapsedDate=( $(date -u -d "0 $FinalDateFmt sec - $StartDateFmt sec" +"%H:%M:%S") )

echo ""   | (tee -a $LOG)
echo "Finished at $FinalDate; elapsed $ElapsedDate" | (tee -a  $LOG)

cp doit.sh riscv.cfg $LOG $OUT_DIR_NAME/

RUN_TAG=$(LC_ALL=C date +'%y%m%dT%H%M')
TARGET_DIR=$OUT_DIR_NAME-$RUN_TAG

rsync --info=progress2 -r $OUT_DIR_NAME/ /nfs/pub/cpu2006/$TARGET_DIR

echo "Running in /nfs/pub/cpu2006/$TARGET_DIR"
ssh sdk@192.168.1.214 "cd /mnt/nfs/cpu2006/$TARGET_DIR; screen -d -m ./run.sh"

#rsync --info=progress2 -r /nfs/pub/cpu2006/$TARGET_DIR/output ./$OUT_DIR_NAME/
