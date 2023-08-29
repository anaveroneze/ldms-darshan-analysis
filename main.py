import os, csv, time, glob, argparse, psutil
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#################################################################################
def process_memory():
    process = psutil.Process(os.getpid())
    mem_info = process.memory_info().rss
    return mem_info
    
def profile(func):

    def wrapper(*args, **kwargs):
        mem_before = process_memory()
        # Run main program
        result = func(*args, **kwargs)
        mem_after = process_memory()
        print("{}: consumed memory: {:,}".format(func.__name__,mem_before, mem_after, mem_after - mem_before))
        return result

    return wrapper

@profile
def main():

    print("Running stressor in background")
    os.system('stress-ng --class cpu --tz -v --all 4 &')
    print("Running application: HACC-IO")
    os.system('mpirun ./apps/hacc-io/hacc_io 100000 ./output/output.txt')
    print("Finish stressors processes")
    os.system('killall -2 stress-ng')

if __name__ == '__main__':
    main()


