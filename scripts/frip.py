#!/usr/bin/env python3

# The recommended way to run this script 
# is from within a conda environment containing deeptools

# conda create -n dtools -c bioconda deeptools
# conda activate dtools
# python frip.py -bams -peaks -outfile

import os
import glob
import pysam
import argparse
import deeptools.countReadsPerBin as crpb


def get_args():
    '''Define and return command line arguments'''
    parser = argparse.ArgumentParser(
        prog='frip.py',
        description='Determines the fraction of reads in peaks for a set of bam\
                files and their corresponding (.narrowPeak) peak files from macs2.\
                This script assumes sample name is the first part of the filename\
                        followed by the kind of mark and split by a underscore') 
    parser.add_argument('-b', '--bamsdir', type=str, required=True,
                        help='Directory containing bam files, and their indexes!')
    parser.add_argument('-p', '--peaksdir', type=str, required=True,
                        help='Directory containing peak files')
    parser.add_argument('-o', '--outfile', type=str, default="frip.csv",
                        help='Path and name of output file, defaults is ./frip.txt')
    parser.add_argument('-t', '--threads', type=int, default=1,
                        help='Number of threads for calculation per bam file, default 1')
    return parser.parse_args()


def calculate_frip(bam,peakfile):
    '''Calculates the fraction of reads in peaks for replicate bam files.'''
    b,pkf=bam,peakfile
    # access deeptools function to get reads in peaks
    cr = crpb.CountReadsPerBin([b], bedFile=pkf, numberOfProcessors=12)
    rip = cr.run()
    total = rip.sum(axis=0)
    # read alignments with pysam
    b1=pysam.AlignmentFile(b)
    # calculate fraction of reads in peaks
    frip = float(total[0]) / b1.mapped
    return frip

def collect_frip_data(b,p,o):    
    # open frip data file to write to
    with open(o, "a") as f:
        f.write("sample\tmark\tfrip\n")
        f.close()
      
    pks=glob.glob(p+"/*.narrowPeak")
    for f in pks:
        # calculate values
        pf=os.path.basename(f)
        smpl=pf.split('.')[1].split('_')[0]
        mrk=pf.split('.')[1].split('_')[1]
        bam=glob.glob(b+f"/*{smpl}_{mrk}*.bam")[0]
        fripn=calculate_frip(bam,f)
        # write to file
        with open(o, "a") as f:
            wstring=f"{smpl}\t{mrk}\t{fripn}\n"
            print(f"Writinng frip to file: {wstring}")
            f.write(wstring)
            f.close()

def main():
    # define command line arguments
    a = get_args()
    bamdir = a.bamsdir
    peaksdir = a.peaksdir
    outfile = a.outfile
    threads = a.threads
    print(f"Calculating frip for bams in\n{bamdir} with\
            peaks in\n{peaksdir} using {threads} threads.")
    collect_frip_data(bamdir, peakdir, outfile)

if __name__ == "__main__":
    main()
