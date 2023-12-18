import os, csv, time, glob, argparse, psutil
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from math import sqrt 
import rpy2.robjects as ro

# Types of anomalies:
# 1. Identify longer operations 
# 2. Identify long intervals between last read/write and a met operation open/close 
# 3. Identify distance between the first rank to finish and others
# 4. Identify long intervals between operations in the same rank
class Job:

    def __init__(self, job, ranks, nodes, users, filename, exe):
        
        self.job = job
        self.ranks = ranks
        self.nodes = nodes
        self.users = users
        self.filename = filename
        self.exe = exe
    
    def print_info(self):

        print("---------------------------------------")
        print("JOB CHARACTERISTICS:")
        print("---------------------------------------")
        print("Job ID:", self.job)
        print(len(self.ranks), "Rank (s):", self.ranks)
        print(len(self.ranks), "Node (s):", self.nodes)
        print("Users:", self.users)
        print("Directory:", self.exe)
        print("Operations filenames:", self.filename)
        print("\n")

def get_statistics(df, self):

    print("---------------------------------------")
    print("EXECUTION SUMMARY:")
    print("---------------------------------------")
    print("Modules being collected:", df['module'].unique())
    print("Module data:", list(df.type).count('MOD'))
    print("Meta data:", list(df.type).count('MET'))
    exec_time = round(df['end'].max() - df['start'].min(), 5)
    print("I/O Execution time:", exec_time, "seconds")
    print("Bandwidth (MiB/second):", round((df['len'].sum()/exec_time)/(1024 ** 2), 2))

    df_rw = df[df['op'].isin(["read", "write"])]
    df_read = df[df['op'] == "read"]
    df_write = df[df['op'] == "write"]

    print("---------------------------------------")
    print("EXECUTION SUMMARY PER APPLICATION PHASE:")
    print("---------------------------------------")

    current_op = None
    phase_start = None
    total_durations = {'read': 0, 'write': 0, 'open': 0, 'close': 0} 

    def update_total_duration(op, phase_start, phase_end, length):
        if current_op is not None and current_op == op:
            total_durations[op] += (phase_end - phase_start)

    for index, row in df.iterrows():
        if current_op is None or current_op != row['op']:
            update_total_duration(current_op, phase_start, row['end'], row['len'])
            current_op = row['op']
            phase_start = row['start']

    # Get the last phase
    update_total_duration(current_op, phase_start, row['end'], row['len'])

    pivot_df = df.pivot_table(index=None, columns='op', values='len', aggfunc='sum')  
    for op, duration in total_durations.items():
        print(f'Duration for {op}s: {round(duration, 4)} seconds')
        bytesproc = round((pivot_df[op].max()/(1024 ** 2))/duration, 4)
        print("Bandwidth:", bytesproc, "(MiB/second)")

    print("\n")
    print("READS (MiB):", df_read['len'].sum()/(1024 ** 2))
    print("Mean duration:", round(df_read['dur'].sum()/(36*6), 2), "seconds")
    print("Max (MiB):", round((df_read['len'].max()/(1024 ** 2)), 2))
    print("Min (MiB):", round((df_read['len'].min()/(1024 ** 2)), 2))
    print("Max per rank (MiB):", round(df_read.groupby('rank')['len'].agg('sum').max() / (1024 ** 2), 2))
    print("Min per rank (MiB):", round(df_read.groupby('rank')['len'].agg('sum').min() / (1024 ** 2), 2))
    print("Bandwidth (MiB/second):", round((df_read['len'].sum()/(df_read['end'].max() - df_read['start'].min()))/(1024 ** 2), 2))

    print("\n")
    print("WRITES (MiB):", df_write['len'].sum()/(1024 ** 2))
    print("Mean duration:", round(df_write['dur'].sum()/(36*6), 2), "seconds")
    print("Max (MiB):", round((df_write['len'].max()/(1024 ** 2)), 2))
    print("Min (MiB):", round((df_write['len'].min()/(1024 ** 2)), 2))
    print("Max per rank (MiB):", round(df_write.groupby('rank')['len'].agg('sum').max() / (1024 ** 2), 2))
    print("Min per rank (MiB):", round(df_write.groupby('rank')['len'].agg('sum').min() / (1024 ** 2), 2))

    print("---------------------------------------")
    print("EXECUTION SUMMARY PER RANK: ")
    print("---------------------------------------")

    # TODO -----

def get_visualizations(filename, figname):

    r = ro.r
    r.source("./code/temporal_vis.R")
    # r.plot_temporal(filename, "./figures/ior/teste1.png")
    # r.plot_long_temporal(filename, "./figures/ior/teste2.png")
    # r.plot_max_temporal(filename, "./figures/ior/teste3.png")
    # r.plot_bandwidth_per_rank(filename, "./figures/ior/teste4.png")
    # r.plot_duration(filename, "./figures/ior/teste5.png")
    r.plot_heatmap_temporal(filename, "./figures/ior/teste6.png")

    return 

def detect_bottlenecks(df):
    # Se o max for muito distante fo mean, reportar:
    df_new['dist'] = df_new['max_dur'] - df_new['median_dur']
    df_bottleneck = df.sort_values(by='dur', ascending=False).head(5)
    print(df_bottleneck)

    for i, row in df_bottleneck.iterrows():

        print("- Rank %d executed a %s for %f seconds" % (row['rank'], row["op"], row["dur"]))
        print("timestamp %s - %s\n" % (row['timestamp'], row['timestamp'] + row["dur"]))

def main():
    
    parser = argparse.ArgumentParser(description="Detect anomalies in I/O benchmarks:")
    parser.add_argument('-i', '--input', type=str, help='Input log', default="")
    parser.add_argument('-p', '--print', type=int, help='Printing dataframe', default=0)

    args = parser.parse_args()   
    df = pd.read_csv(args.input, engine="pyarrow")

    df['start'] = df['timestamp'] - df['dur']
    df['end'] = df['timestamp']

    if(args.print):
        print(df)

    # Get basic info about the job:
    local_df = pd.DataFrame()
    for i in df.job_id.unique():

        local_df = df[df['job_id'] == i]
        job = Job(i, local_df['rank'].unique(), local_df['ProducerName'].unique(),local_df['uid'].unique(), 
            local_df['file'].unique(), local_df['exe'].unique())
        
        # Job characteristics
        job.print_info()     
        # Job profile
        get_statistics(local_df, job)
        # Job visualizations
        get_visualizations(args.input, "./figures/ior/teste.png")

if __name__ == '__main__':

    start_time_exec = time.time()
    main()
    # print("Execution time: %s sec" % (time.time() - start_time_exec))