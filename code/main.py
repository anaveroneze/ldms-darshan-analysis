import os, csv, time, glob, argparse, psutil
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from math import sqrt 
import rpy2.robjects as ro
import seaborn as sns
from datetime import datetime

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
        print(len(self.ranks), "Rank (s):", sorted(self.ranks))
        print(len(self.ranks), "Node (s):", sorted(self.nodes))
        print("Users:", self.users)
        print("Directory:", self.exe)
        # print("Operations filenames:", self.filename)

def get_statistics(df, output_file, self):

    with open(output_file, 'w') as f:

        def write_to_file(*args):
            print(" ".join(map(str, args)), file=f, flush=True)

        write_to_file("---------------------------------------")
        write_to_file("JOB CHARACTERISTICS:")
        write_to_file("---------------------------------------")
        write_to_file("Job ID:", self.job)
        write_to_file(len(self.ranks), "Rank (s):", sorted(self.ranks))
        write_to_file(len(self.ranks), "Node (s):", sorted(self.nodes))
        write_to_file("Users:", self.users)
        write_to_file("Directory:", self.exe)

        write_to_file("Modules collected:", df['module'].unique())
        write_to_file("Module data (MOD):", list(df.type).count('MOD'))
        write_to_file("Meta data (MET):", list(df.type).count('MET'))
        exec_time = round(df['end'].max() - df['start'].min(), 5)
        write_to_file("I/O execution time:", exec_time, "seconds")
        write_to_file("Total bandwidth (MiB/second):", round((df['len'].sum() / exec_time) / (1024 ** 2), 2))

        df_rw = df[df['op'].isin(["read", "write"])]
        df_read = df[df['op'] == "read"]
        df_write = df[df['op'] == "write"]

        write_to_file("---------------------------------------")
        write_to_file("EXECUTION SUMMARY PER APPLICATION PHASE:")
        write_to_file("---------------------------------------")

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
            write_to_file(f'Duration for {op}s: {round(duration, 4)} seconds')
            if op == "read" or op == "write":
                bytesproc = round((pivot_df[op].max() / (1024 ** 2)) / duration, 4)
                write_to_file("Bandwidth:", bytesproc, "(MiB/second)")

        write_to_file("\n")
        write_to_file("READS (MiB):", round(df_read['len'].sum() / (1024 ** 2)))
        write_to_file("Max MiB per rank:", round(df_read.groupby('rank')['len'].agg('sum').max() / (1024 ** 2)))
        write_to_file("Min MiB per rank:", round(df_read.groupby('rank')['len'].agg('sum').min() / (1024 ** 2)))
        write_to_file("Bandwidth (MiB/second):", round((df_read['len'].sum() / (df_read['end'].max() - df_read['start'].min())) / (1024 ** 2), 2))
        write_to_file("\nWRITES (MiB):", round(df_write['len'].sum() / (1024 ** 2)))
        write_to_file("Max MiB per rank:", round(df_write.groupby('rank')['len'].agg('sum').max() / (1024 ** 2)))
        write_to_file("Min MiB per rank:", round(df_write.groupby('rank')['len'].agg('sum').min() / (1024 ** 2)))
        write_to_file("Bandwidth (MiB/second):", round((df_write['len'].sum() / (df_write['end'].max() - df_write['start'].min())) / (1024 ** 2),2))

        # IMBALANCE METRICS:
        # Average = sum time computing / number of ranks
        # Imbalance time = time that would be saved if the load was perfectly balanced across resources
        # Percent Imbalance = performance that could be gained if load was perfectly balanced
        # Imbalance Percentage = percentage of time that resources (excluding the slowest one) are
        # not involved in computing
        write_to_file("---------------------------------------")
        write_to_file("LOAD IMBALANCE METRICS:")
        write_to_file("---------------------------------------")
        # Get difference between execution time and time processing I/O per rank
        df_idle = df.groupby('rank')['dur'].sum().reset_index()
        df_idle.columns = ['Rank', 'I/O Time']
        df_idle['Total time - I/O Time'] = exec_time - df_idle['I/O Time']
        df_idle = df_idle.sort_values(by='Total time - I/O Time', ascending=False)

        write_to_file("Total execution time:", exec_time)
        num_ranks = df_idle['I/O Time'].nunique()
        average = df_idle['I/O Time'].sum() / num_ranks
        write_to_file("- Average:", round(average), "seconds")
        it = df_idle['I/O Time'].max() - average
        write_to_file("- Imbalance Time:", round(it, 2), "seconds")
        pi = ((df_idle['I/O Time'].max() / average) - 1) * 100
        write_to_file("- Percent Imbalance:", round(pi, 2), "%")
        ip = (it / df_idle['I/O Time'].max()) * (num_ranks / (num_ranks - 1))
        write_to_file("- Imbalance Percentage:", round(ip, 2), "%")
        std = np.std(df_idle['I/O Time'])
        write_to_file("- Standard deviation", round(std, 2))

        write_to_file("---------------------------------------")
        write_to_file("PROFILE PER RANK: ")
        write_to_file("---------------------------------------")
        write_to_file("Total time without executing I/O operations:")
        df['start'] = pd.to_datetime(df['start'], unit='s').dt.round('S')
        df['end'] = pd.to_datetime(df['end'], unit='s').dt.round('S')
        write_to_file(df_idle)

    # # Iterate over each operation
    # for op in df_delay['op'].unique():

    #     op_data = df_delay[df_delay['op'] == op]
    #     rank_fast = op_data.loc[op_data['end'].idxmin()]['rank']
    #     rank_slow = op_data.loc[op_data['end'].idxmax()]['rank']

    #     time_fast = op_data[op_data['rank'] == rank_fast]['end'].values[0]
    #     time_slow = op_data[op_data['rank'] == rank_slow]['end'].values[0]
    #     time_diff = time_slow - time_fast

    #     # Append the results to the result DataFrame
    #     result_df = pd.concat([result_df, pd.DataFrame([{'op': op, 'rank_fast': rank_fast, 'rank_slow': rank_slow, 
    #         'time_fast': time_fast, 'time_slow': time_slow, 'diff': time_diff}])], ignore_index=True)

def get_visualizations_R(filename, figname):

    r = ro.r
    r.source("./code/temporal_vis.R")
    r.plot_temporal(filename, "./figures/ior/teste1.png")
    r.plot_long_temporal(filename, "./figures/ior/teste2.png")
    r.plot_max_temporal(filename, "./figures/ior/teste3.png")
    r.plot_bandwidth_per_rank(filename, "./figures/ior/teste4.png")
    r.plot_duration(filename, "./figures/ior/teste5.png")

    return 

def get_visualizations_py(df, figname):

    df.read = df[df['op'] == "read"]
    mask = df.read['len']>0 
    df.read = df.read[mask]
    fig, ax = plt.subplots(1, 1, figsize=(20, 6))  # Adjust the figsize parameter for figure dimensions

    df.read['timestamp'] = pd.to_datetime(df.read['timestamp'], unit='s').dt.round('S')
    df.read['dur'] = pd.to_timedelta(df.read['dur'], unit='s').dt.round('S')
    df.read['start'] = df.read['timestamp'] - df.read['dur']
    df.read['rank_time'] = df.read['start'] - min(df.read['start'])

    df.read['rank_time'] = pd.cut(df.read['start'].dt.round('S'), bins=20)
    df.read = df.read.groupby(by=["op","rank_time"])["len"].sum().reset_index()
    df.read['len'] = df.read['len'] / 1024 / 1024
    df.read = df.read.pivot(index="op", columns="rank_time", values="len")
    sns.heatmap(ax=ax, data=df.read, cmap="mako", cbar_kws={'label': 'MiB processed'})
    ax.set_ylabel("Operation")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    ax.set_xlabel("Timestamp")
    plt.tight_layout()
    plt.savefig("./figures/ior/teste6-read.png")
    plt.clf()
    plt.close()
    
    #################################################################
    df.write = df[df['op'] == "write"]
    mask = df.write['len']>0 
    df.write = df.write[mask]
    fig, ax = plt.subplots(1, 1, figsize=(20, 6))  # Adjust the figsize parameter for figure dimensions

    df.write['timestamp'] = pd.to_datetime(df.write['timestamp'], unit='s').dt.round('S')
    df.write['dur'] = pd.to_timedelta(df.write['dur'], unit='s').dt.round('S')
    df.write['start'] = df.write['timestamp'] - df.write['dur']
    df.write['rank_time'] = df.write['start'] - min(df.write['start'])

    df.write['rank_time'] = pd.cut(df.write['start'], bins=20)
    df.write = df.write.groupby(by=["op","rank_time"])["len"].sum().reset_index()
    df.write['len'] = df.write['len'] / 1024 / 1024
    df.write = df.write.pivot(index="op", columns="rank_time", values="len")
    sns.heatmap(ax=ax, data=df.write, cmap="mako", cbar_kws={'label': 'MiB processed'})
    ax.set_ylabel("Operation")
    ax.set_xlabel("Timestamp")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig("./figures/ior/teste6-write.png")
    plt.clf()
    plt.close()

    #################################################################3
    mask = df['len']>0 
    df = df[mask]
    fig, ax = plt.subplots(1, 1, figsize=(10, 10))  # Adjust the figsize parameter for figure dimensions

    df['start'] = df['timestamp'] - df['dur']
    df['rank_time'] = df['start'] - min(df['start'])
    df['rank_time'] = pd.cut(df['start'], bins=10)
    df = df.groupby(by=["rank","rank_time"])["len"].sum().reset_index()
    df['len'] = df['len'] / 1024 / 1024
    df = df.pivot(index="rank", columns="rank_time", values="len")
    sns.heatmap(ax=ax, data=df, cmap="mako", cbar_kws={'label': 'MiB processed'})
    ax.set_ylabel("Rank")
    ax.set_xlabel("Timestamp")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig("./figures/ior/teste7.png")
    plt.clf()
    plt.close()

    return 

def detect_bottlenecks(df):
    # Se o max for muito distante fo mean, reportar:
    df_new['dist'] = df_new['max_dur'] - df_new['median_dur']
    df_bottleneck = df.sort_values(by='dur', ascending=False).head(5)
    print(df_bottleneck)

    for i, row in df_bottleneck.iterrows():

        print("- Rank %d executed a %s for %f seconds" % (row['rank'], row["op"], row["dur"]))
        print("timestamp %s - %s\n" % (row['timestamp'], row['timestamp'] + row["dur"]))

def correlate_system(filename, filename_sys):
    
    r = ro.r
    r.source("./code/system_vis.R")
    r.plot_temporal(filename, filename_sys, "./figures/ior/teste6.png")

    return 

def main():
    
    parser = argparse.ArgumentParser(description="Detect anomalies in I/O benchmarks:")
    parser.add_argument('-i', '--input', type=str, help='Input log', default="")
    parser.add_argument('-s', '--system', type=str, help='Input system log', default="")
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
        output_file = args.input.replace(".csv", ".txt")
        get_statistics(local_df, output_file, job)
        # Job visualizations
        # get_visualizations_R(args.input, "./figures/ior/teste.png")
        # get_visualizations_py(local_df, "./figures/ior/teste.png")

    if(args.system):
        correlate_system(args.input, args.system)

if __name__ == '__main__':

    start_time_exec = time.time()
    main()
    # print("Execution time: %s sec" % (time.time() - start_time_exec))