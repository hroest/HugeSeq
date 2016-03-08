#!/bin/bash -e

module load hugeseq/2.0
# make Hugeseq work even when not in default location
export PATH=$HUGESEQ_HOME/bin/:$PATH
# bring down the memory usage, leads to fewer killed jobs
export MALLOC_ARENA_MAX=2
export TMP=$1
echo $TMP
shift
export LOGFILE=$1
echo $LOGFILE
shift

$*
