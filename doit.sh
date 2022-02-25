#!/bin/bash
# (C) Syntacore 2022
# Cross-compile SPEC CPU 2006 on host and run remotely on fpga

# FIXME: parameterize folders and board

# FIXME: set path to cross-compiler, e.g. $CROSS_TOOLS/bin
export PATH="$PATH:/home/yakush-sc/dev/riscv-rel/riscv-gcc-11.1.0-g477443e-211230T1056/bin"

# INFO: mount & install SPEC: mount SPEC2006 sudo mount -o loop /mnt/c/Devel/cpu2006-1.2.iso /home/yakush-sc/dev/spec2006/
export SPEC_DIR=/home/yakush-sc/dev/bench/cpu2006/
export SPEC_DIR="/home/aleksashqa/dev/spec2006"

export INPUT_TYPE=ref

# Set benchmark list
export BENCHMARKS_STR="400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar 483.xalancbmk"
 
#  Set config name to specify toolchain path
export CONFIG=rpi4

case $CONFIG in
    riscv)
        TOOLCHAIN_PATH="/projects/tools/riscv-gcc-11.1.0-g477443e-220131T0953/bin"
        CC=riscv64-unknown-linux-gnu-gcc
        CXX=riscv64-unknown-linux-gnu-g++
        ;;
    rpi3)
        TOOLCHAIN_PATH="/projects/tools/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin"
        CC=aarch64-none-linux-gnu-gcc
        CXX=aarch64-none-linux-gnu-g++
        ;;
    rpi4)
        TOOLCHAIN_PATH="/projects/tools/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin"
        CC=aarch64-none-linux-gnu-gcc
        CXX=aarch64-none-linux-gnu-g++
        ;;
    *)
        echo "Unknown config: $CONFIG"
        exit 1
        ;;
esac

export PATH="$PATH:$TOOLCHAIN_PATH"

# compile & run remotely
OUT_DIR_NAME=$CONFIG-spec-$INPUT_TYPE
BUILD_DIR=$PWD/build

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
echo ""   | (tee -a $LOG)
echo "CXX" | (tee -a $LOG)
which $CXX | (tee -a $LOG)
$CXX -v 2>&1 | (tee -a $LOG)
echo ""   | (tee -a $LOG)

./gen_binaries.sh --compile --copy 2>&1 | (tee -a $LOG)

FinalDate=$(date)

StartDateFmt=$(date -u -d "$StartDate" +"%s")
FinalDateFmt=$(date -u -d "$FinalDate" +"%s")
ElapsedDate=( $(date -u -d "0 $FinalDateFmt sec - $StartDateFmt sec" +"%H:%M:%S") )

echo ""   | (tee -a $LOG)
echo "Finished at $FinalDate; elapsed $ElapsedDate" | (tee -a  $LOG)

cp doit.sh $CONFIG.cfg $LOG $OUT_DIR_NAME/

# RUN_TAG=$(LC_ALL=C date +'%y%m%dT%H%M')
# TARGET_DIR=$OUT_DIR_NAME-$RUN_TAG
# 
# rsync --info=progress2 -r $OUT_DIR_NAME/ /nfs/pub/cpu2006/$TARGET_DIR
# 
# FIXME: setup board 
# echo "Running in /nfs/pub/cpu2006/$TARGET_DIR"
# ssh sdk@192.168.1.155 "cd /mnt/nfs/cpu2006/$TARGET_DIR; screen -d -m ./run.sh"
# 
# rsync --info=progress2 -r /nfs/pub/cpu2006/$TARGET_DIR/output ./$OUT_DIR_NAME/
