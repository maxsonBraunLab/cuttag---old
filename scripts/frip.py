#!/usr/bin/env python3

# Jake VanCampen
# vancampe@ohsu.edu
# The recommended way to run this script 
# is from within a conda environment containing deeptools

# create a conda environment named dtools

# conda create -n dtools -c bioconda deeptools
# conda activate dtools
# python frip.py -b /path/to/bam/dir -p /path/to/peaks/dir -o /path/to/outfile.csv

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
                This script assumes sample name is the first part of the filenames\
                in the bams and peaks directories followed by the kind of mark and\
                split by a underscore e.g. SM1_H3K4me3_blabla.bam, SM1_H3K4me3_macs2.narrowPeak') 
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
    num_lines = sum(1 for line in open(peakfile))
    if num_lines < 10:
        frip = "NA"
    else:
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
    # warn about clobber
    if os.path.isfile(o):
        print(f"WARN: {o} exists, overwriting")

    try:
        # open frip data file to write to
        with open(o, "w") as f:
            f.write("sample\tmark\tfrip\n")
    except:
        print("Error opening output file.")
      
    pks=glob.glob(p+"/*.narrowPeak")
    if len(pks) < 2:
        print("There are feweer than two peak files here, you\
               didn't provide a path that contains peak files,\
               or you do not have permission to be at that path")
    else:
        for f in pks:
            
            # calculate values
            pf=os.path.basename(f)
            smpl=pf.split('.')[0].split('_')[0]
            mrk=pf.split('.')[0].split('_')[1]
            bam=glob.glob(b+f"/*{smpl}_{mrk}*.bam")[0]
            fripn=calculate_frip(bam,f)
            # write to file
            with open(o, "a") as f:
                wstring=f"{smpl}\t{mrk}\t{fripn}\n"
                print(f"Writinng frip to file: {wstring}")
                f.write(wstring)

def main():
    # define command line arguments
    a = get_args()
    bamdir = a.bamsdir
    peaksdir = a.peaksdir
    outfile = a.outfile
    threads = a.threads
    print(f"Calculating frip for bams in\n{bamdir} with\
            peaks in\n{peaksdir} using {threads} threads.")
    collect_frip_data(bamdir, peaksdir, outfile)

if __name__ == "__main__":
    main()
