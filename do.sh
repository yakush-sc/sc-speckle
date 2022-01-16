#!/bin/bash

export PATH="$PATH:/home/yakush-sc/dev/riscv-rel/riscv-gcc-11.1.0-g477443e-211230T1056/bin"
#export PATH="$PATH:/home/yakush-sc/dev/sc-ide/out/riscv-gcc-10.1.0-gaeccc7a-220110T2139/bin"

export SPEC_DIR=/home/yakush-sc/dev/cpu2006/

# compile & run remotely
export INPUT_TYPE=ref
OUT_DIR=riscv-spec-$INPUT_TYPE

CC=riscv64-unknown-linux-gnu-gcc
CXX=riscv64-unknown-linux-gnu-g++

StartDate=$(date)
rm -rf ./$OUT_DIR/
mkdir -p $OUT_DIR
echo "Started at $StartDate" | (tee $OUT_DIR/compile-report.txt)
echo ""   | (tee -a $OUT_DIR/compile-report.txt)
echo "CC" | (tee -a $OUT_DIR/compile-report.txt)
which $CC | (tee -a $OUT_DIR/compile-report.txt)
$CC -v 2>&1 | (tee -a $OUT_DIR/compile-report.txt)
#echo | $CC  -x c   -march=rv64gc -mabi=lp64d -E -Wp,-v - | (tee -a $OUT_DIR/compile-report.txt)
echo ""   | (tee -a $OUT_DIR/compile-report.txt)
echo "CXX" | (tee -a $OUT_DIR/compile-report.txt)
which $CXX | (tee -a $OUT_DIR/compile-report.txt)
$CXX -v 2>&1 | (tee -a $OUT_DIR/compile-report.txt)
#echo | $CXX -x c++ -march=rv64gc -mabi=lp64d -E -Wp,-v - | (tee -a $OUT_DIR/compile-report.txt)
echo ""   | (tee -a $OUT_DIR/compile-report.txt)

mv $OUT_DIR/compile-report.txt ./compile-report.txt
./gen_binaries.sh --compile --copy 2>&1 | (tee -a ./compile-report.txt)
mv ./compile-report.txt $OUT_DIR/compile-report.txt

FinalDate=$(date)

StartDateFmt=$(date -u -d "$StartDate" +"%s")
FinalDateFmt=$(date -u -d "$FinalDate" +"%s")
ElapsedDate=( $(date -u -d "0 $FinalDateFmt sec - $StartDateFmt sec" +"%H:%M:%S") )

echo ""   | (tee -a $OUT_DIR/compile-report.txt)
echo "Finished at $FinalDate; elapsed $ElapsedDate" | (tee -a  $OUT_DIR/compile-report.txt)

cp do.sh riscv.cfg $OUT_DIR/

rm -rf /nfs/pub/cpu2006/$OUT_DIR

rsync --info=progress2 -r $OUT_DIR /nfs/pub/cpu2006/
ssh sdk@192.168.1.214 "cd /mnt/nfs/cpu2006/$OUT_DIR; nohup ./run.sh"
rsync --info=progress2 -r /nfs/pub/cpu2006/$OUT_DIR/output ./$OUT_DIR/
