#!/bin/bash

set -e

if [ $# -lt 1 ]
then
        echo "Usage: $0 <vcf>"
        exit 1
fi

START_VCF=`cd \`dirname $1\`; pwd`/`basename $1`
PREFIX=`dirname $START_VCF`
SUFFIX=`basename $START_VCF`
SAMPLE=${SUFFIX/.gatk.vcf/}


SNV_VCF=$PREFIX/$SAMPLE.SNV.vcf
SNV_RECAL_VCF=$PREFIX/$SAMPLE.vqsr.SNV.vcf
SNV_RECAL=$PREFIX/$SAMPLE.tmp.snp.vcf
SNV_TRANCHES=$PREFIX/$SAMPLE.tranches.gatk.snp.recal.csv
SNV_RSCRIPT=$PREFIX/$SAMPLE.gatk.recal.snp.R


INDEL_VCF=$PREFIX/$SAMPLE.INDEL.vcf
INDEL_RECAL_VCF=$PREFIX/$SAMPLE.vqsr.INDEL.vcf
INDEL_RECAL=$PREFIX/$SAMPLE.tmp.indel.vcf
INDEL_TRANCHES=$PREFIX/$SAMPLE.tranches.gatk.indel.recal.csv
INDEL_RSCRIPT=$PREFIX/$SAMPLE.gatk.recal.indel.R

# amin
DIR_PREFIX=/srv/gs1/projects/scg/data/hugeseq/

/usr/java/latest/bin/java -Xmx6g -Xms6g -jar $GATK/GenomeAnalysisTK.jar \
   -T SelectVariants \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -V $START_VCF \
   -o $SNV_VCF \
   -selectType SNP &> $PREFIX/$SAMPLE.select.snv.log

/usr/java/latest/bin/java -Xmx6g -Xms6g -jar $GATK/GenomeAnalysisTK.jar \
   -T VariantRecalibrator \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -input $SNV_VCF \
   -resource:hapmap,VCF,known=false,training=true,truth=true,prior=15.0 \
        $DIR_PREFIX/resources/referencefiles/hapmap/hapmap_3.3.hg19.sites.vcf \
   -resource:omni,VCF,known=false,training=true,truth=false,prior=12.0 \
        $DIR_PREFIX/resources/referencefiles/omni/1000G_omni2.5.hg19.sites.vcf \
   -resource:dbsnp,VCF,known=true,training=false,truth=false,prior=6.0 \
        $DIR_PREFIX/resources/referencefiles/dbsnp/dbsnp_135.hg19.vcf \
   -an QD -an HaplotypeScore -an MQRankSum -an ReadPosRankSum -an MQ -an FS \
   -mode SNP \
   --maxGaussians 4 \
   -recalFile $SNV_RECAL \
   -tranchesFile $SNV_TRANCHES \
   -rscriptFile $SNV_RSCRIPT &> $PREFIX/$SAMPLE.recalibrate.snv.log

/usr/java/latest/bin/java -Xmx3g -Xms3g -jar $GATK/GenomeAnalysisTK.jar \
   -T ApplyRecalibration \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -input $SNV_VCF \
   --ts_filter_level 99.0 \
   -tranchesFile $SNV_TRANCHES \
   -recalFile $SNV_RECAL \
   -o $SNV_RECAL_VCF \
   --mode SNP &> $PREFIX/$SAMPLE.apply.snv.log

/usr/java/latest/bin/java -Xmx6g -Xms6g -jar $GATK/GenomeAnalysisTK.jar \
   -T SelectVariants \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -V $START_VCF \
   -o $INDEL_VCF \
   -selectType INDEL &> $PREFIX/$SAMPLE.select.indel.log

/usr/java/latest/bin/java -Xmx6g -Xms6g -jar $GATK/GenomeAnalysisTK.jar \
   -T VariantRecalibrator \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -input $INDEL_VCF \
   -resource:mills,VCF,known=true,training=true,truth=true,prior=12.0 \
        $DIR_PREFIX/resources/referencefiles/indel/Mills_and_1000G_gold_standard.indels.hg19.sites.rightHeader.vcf \
   -an QD -an FS -an HaplotypeScore -an ReadPosRankSum  \
   -mode INDEL \
   --maxGaussians 4 \
   -recalFile $INDEL_RECAL \
   -tranchesFile $INDEL_TRANCHES \
   -rscriptFile $INDEL_RSCRIPT &> $PREFIX/$SAMPLE.recalibrate.indel.log

/usr/java/latest/bin/java -Xmx6g -Xms6g -jar $GATK/GenomeAnalysisTK.jar \
   -T ApplyRecalibration \
   #-R $DIR_PREFIX/resources/referencefiles/hg19/hg19.fa \
   -R $DIR_PREFIX/resources/referencefiles/ucsc-hg19/bwa-0.7.4/hg19.fa \
   -input $INDEL_VCF \
   --ts_filter_level 99.0 \
   -tranchesFile $INDEL_TRANCHES \
   -recalFile $INDEL_RECAL \
   -o $INDEL_RECAL_VCF \
   --mode INDEL &> $PREFIX/$SAMPLE.apply.indel.log 

rm $SNV_VCF, $SNV_RECAL, $SNV_TRANCHES, *.log, $INDEL_VCF, $INDEL_RECAL, $INDEL_TRANCHES
