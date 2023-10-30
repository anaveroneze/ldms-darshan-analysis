import os, csv, time, glob, argparse, psutil
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from math import sqrt 

# Input LDMS-Darshan file
# ./ior/eclipse/darshan-ldms-output/csv/17533880-IOR_pscratch.csv
def main():
    
    parser = argparse.ArgumentParser(description="Detect anomalies in I/O benchmarks:")
    parser.add_argument('-input', type=str, help='Input log', default="")

    args = parser.parse_args()   
    df = pd.read_csv(args.input, engine="pyarrow")
    print(df)

    # Group per rank and operation and get basic statistics
    df_new = df.groupby(['op', 'rank']).agg(mean_dur=('dur', np.mean),
                std_dur=('dur', np.std),
                median_dur=('dur', np.median),
                min_dur=('dur', np.min),
                max_dur=('dur', np.max)).reset_index()

    print(df_new.to_string())

    # Se o max for muito distante fo mean, reportar:
    df_new['dist'] = df_new['max_dur'] - df_new['median_dur']


    df_bottleneck = df.sort_values(by='dur', ascending=False).head(5)
    print(df_bottleneck)

    for i, row in df_bottleneck.iterrows():

        print("- Rank %d executed a %s for %f seconds" % (row['rank'], row["op"], row["dur"]))
        print("timestamp %s - %s\n" % (row['timestamp'], row['timestamp'] + row["dur"]))

if __name__ == '__main__':

    start_time_exec = time.time()
    main()
    print("Execution time: %s sec" % (time.time() - start_time_exec))