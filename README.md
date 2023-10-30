# ldms-darshan-analysis

## Darshan-LDMS absolute timestamp

Explore running I/O benchmarks with system stressors to show that we can use the system timestamps collected by Darshan-LDMS to diagnose application bottlenecks automatically.

Using stress-ng for stressing the system: https://wiki.ubuntu.com/Kernel/Reference/stress-ng

```sh
sudo apt install stress-ng
stress-ng --matrix 1 -t 1m -v
```

Using mixed stressor classes: 
```sh
stress-ng --cpu 0 --cpu-method fft &
stress-ng --cpu 0 --matrix-method frobenius &
stress-ng --tz --lsearch 0  --all 1 &
```

For a specific class:
```sh
stress-ng --class cpu --tz -v --all 4 & 
stress-ng --class cpu-cache --tz -v --all 4 &
stress-ng --class io --tz -v --all 4 &
stress-ng --class filesystem --tz -v --all 4 &
stress-ng --class memory --tz -v --all 4 &
```

We will collect LDMS-Darshan and system logs (meminfo, procstat, lustre, dstat).

## First test:

1. HACCIO with 50.000.000 particles and specific classes running in background during all execution:
```sh
stress-ng --class cpu --tz -v --all 4 & 
stress-ng --class cpu-cache --tz -v --all 4 &
stress-ng --class io --tz -v --all 4 &
stress-ng --class filesystem --tz -v --all 4 &
stress-ng --class memory --tz -v --all 4 &
```

To finish the stressors running in background:

```sh
killall -2 stress-ng
```

2. HACCIO with 100.000.000 particles (or other setup that exceeds 10sec execution) and specific classes running in background for 10 seconds:
```sh
stress-ng --class cpu --tz -v --all 4 -t 10s & 
stress-ng --class cpu-cache --tz -v --all 4 -t 10s &
stress-ng --class io --tz -v --all 4 -t 10s &
stress-ng --class filesystem --tz -v --all 4 -t 10s &
stress-ng --class memory --tz -v --all 4 -t 10s &
```

Run one stressor for each run, so a total of 10 experiments + 2 normal executions (no stressors).

# Experimental Design 

Organizing experimental plan for reporting the benefits of having the absolute timestamp collected by Darshan-LDMS to  identify I/O bottlenecks, by using the LDMS-Darshan information itself, and also by correlating with other system telemetry data. We will run I/O benchmarks and real applications with and without system stressors and evalutate the performance of the experiments using LDMS-Darshan logs.

## Applications

We selected 3 microbenchmarks (HACCIO, IOR, IOZone) and 2 real applications (CANDLE and VPIC-IO):

- **HACCIO**: Available in: https://www.vi4io.org/tools/benchmarks/hacc_io
  - I/O performance benchmark using N-body simulations
  - The parameter values determines the number of particles used
  - Interface for POSIX and MPI-IO
  - Each process writes the number of particles * 38 bytes + 24MB header
  - Output shows the bandwidth per process, the bytes per process and the maximum execution time
  - Configure and Run:

```bash
cd ./benchmarks 
git clone https://github.com/glennklockwood/hacc-io.git
mv hacc-io/ haccio/
cd haccio/
make clean
make CXX=mpicxx

# Run for
mpirun -np 2 ./hacc_io 10000000 outputfile
mpirun -np 2 ./hacc_io 5000000 outputfile
```

- **IOR**: Available in: https://github.com/hpc/ior
  - User can controll the request size
  - Interface for POSIX, MPI-IO, HDF5, HDFS, S3, NCMPI, IME, MMAP, RADOS 
  - ten iterations of one segment with a 32MB lock size using 4MB transfer sizes 
  - Configure and Run:

```bash
git clone https://github.com/hpc/ior.git
cd ior/
./bootstrap
./configure
make
make check

# Run for
./src/ior -a POSIX
```

- **IOZone**: Available in: https://www.iozone.org/
  - Interface for POSIX
  - Configure and Run:
  
```bash
wget https://www.iozone.org/src/current/iozone3_493.tgz
tar -xzvf iozone3_493.tgz
rm *tgz
mv iozone3_493/ iozone
cd iozone/src/current/
make linux-AMD64

# Run for
./iozone -a
```

- **CORAL-2: VPIC-IO**: Available in: https://github.com/lanl/vpic
  - A highly optimized and scalable particle physics simulation developed by Los Alamos National Lab, using 2D, 2D or 3D array
  - Evaluates I/O
  - Uses MPI and threads
  - Configure and Run:

```bash
git clone https://github.com/lanl/vpic.git
cd vpic
mkdir build
cd build
../arch/reference-Release
make

# Run for the input deck
./bin/vpic ../sample/harris 
mpirun -n 2 ./harris.Linux --tpp 8
```

- **CANDLE (P3B3)**: Available in: https://github.com/ECP-CANDLE/Benchmarks/tree/master/Pilot3/P3B3
  - Pilot3 (P3) benchmarks are formed out of problems and data at the population level. The high level goal of the problem behind the P3 benchmarks is to predict cancer recurrence in patients based on patient related data.
  - Configure experiment information in the "p3b3_default_model.txt" file
  - More information in the README.setup.linux CANDLE file
  - Configure and Run 
  
```sh
pip install -r requirements-candle.txt
wget https://github.com/ECP-CANDLE/Benchmarks/archive/refs/tags/v0.4.tar.gz
tar -xzvf v0.4.tar.gz
mv Benchmarks-0.4/ candle/
rm v0.4.tar.gz

# Run for
python3 ./candle/Pilot3/P3B3/p3b3_baseline_keras2.py
```

Using the configuring file (./Pilot3/P3B3/p3b3_default_model.txt):
```txt
[Global_Params]
data_url = 'ftp://ftp.mcs.anl.gov/pub/candle/public/benchmarks/Pilot3/'
train_data = 'P3B3_data.tar.gz'
model_name = 'p3b3'
learning_rate = 0.0001
batch_size = 10
epochs = 10
dropout = 0.5
optimizer = 'adam'
wv_len = 300
filter_sizes = 3
filter_sets = 3
num_filters = 100
emb_l2 = 0.001
w_l2 = 0.01
task_list = [0, 2, 3]
task_names = ['site', 'laterality', 'histology', 'grade']
```

## Stressors

Using stress-ng for stressing the system: https://wiki.ubuntu.com/Kernel/Reference/stress-ng

Configuring for different parameters:

```sh
!#/bash/sh

declare -a arr=("cpu" "cpu-cache" "device" "io" "interrupt" "filesystem" "memory" "network" "os")

## now loop through the above array
for class_type in "${arr[@]}"
do
   echo "stress-ng --class $class_type --tz -v --seq 0 &"
   echo "stress-ng --class $class_type --tz -v --all 1 &"
   echo "stress-ng --class $class_type --tz -v --all 2 &"
   echo "stress-ng --class $class_type --tz -v --all 4 &"
done

```

Different setups for stressors:
```sh
stress-ng --class cpu --tz -v --seq 0 &
stress-ng --class cpu --tz -v --all 1 &
stress-ng --class cpu --tz -v --all 2 &
stress-ng --class cpu --tz -v --all 4 &
stress-ng --class cpu-cache --tz -v --seq 0 &
stress-ng --class cpu-cache --tz -v --all 1 &
stress-ng --class cpu-cache --tz -v --all 2 &
stress-ng --class cpu-cache --tz -v --all 4 &
stress-ng --class device --tz -v --seq 0 &
stress-ng --class device --tz -v --all 1 &
stress-ng --class device --tz -v --all 2 &
stress-ng --class device --tz -v --all 4 &
stress-ng --class io --tz -v --seq 0 &
stress-ng --class io --tz -v --all 1 &
stress-ng --class io --tz -v --all 2 &
stress-ng --class io --tz -v --all 4 &
stress-ng --class interrupt --tz -v --seq 0 &
stress-ng --class interrupt --tz -v --all 1 &
stress-ng --class interrupt --tz -v --all 2 &
stress-ng --class interrupt --tz -v --all 4 &
stress-ng --class filesystem --tz -v --seq 0 &
stress-ng --class filesystem --tz -v --all 1 &
stress-ng --class filesystem --tz -v --all 2 &
stress-ng --class filesystem --tz -v --all 4 &
stress-ng --class memory --tz -v --seq 0 &
stress-ng --class memory --tz -v --all 1 &
stress-ng --class memory --tz -v --all 2 &
stress-ng --class memory --tz -v --all 4 &
stress-ng --class network --tz -v --seq 0 &
stress-ng --class network --tz -v --all 1 &
stress-ng --class network --tz -v --all 2 &
stress-ng --class network --tz -v --all 4 &
stress-ng --class os --tz -v --seq 0 &
stress-ng --class os --tz -v --all 1 &
stress-ng --class os --tz -v --all 2 &
stress-ng --class os --tz -v --all 4 &
```

## Job Execution Setup
### Scontrol
The output of ``scontrol show job <job-id>`` of the HACC-IO execution with 10 million particles, 16 nodes and 32 tasks per node:

```sh
 Command=/projects/ovis/darshanConnector/common/darshan/darshan-test/regression/cray-module-common/slurm-submit.sl --ntasks-per-node=32 /projects/ovis/darshanConnector/apps/rhel9.7/hacc-io/hacc_io 10000000 /pscratch/<user>/haccTest/darshan
   WorkDir=/ceeprojects/ovis/darshanConnector/common/darshan/darshan-test/regression/test-cases
   StdErr=/pscratch/<user>/darshan-ldms-output/17301435-HACC_pscratch_10.err
   StdIn=/dev/null
   StdOut=/pscratch/<user>/darshan-ldms-output/17301435-HACC_pscratch_10.out
```
### slurm-submit.sl
The ``slurm-submit.sl`` is where the stress-ng and job are started and is shown below:
```sh
#!/bin/bash -l
export PBS_JOBID=$SLURM_JOB_ID
export DARSHAN_LOGFILE=$DARSHAN_TMP/${PROG}.${PBS_JOBID}.darshan

mkdir /tmp/stress-tmp/

{
stress-ng --temp-path /tmp/stress-tmp/ --class cpu --tz -v --all 4 | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class cpu-cache --tz -v --all 4 | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class io --tz -v --all 4 | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class filesystem --tz -v --all 4 | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class memory --tz -v --all 4 | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &

#stress-ng --temp-path /tmp/stress-tmp/ --class cpu --tz -v --all 4 -t 10s | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class cpu-cache --tz -v --all 4 -t 10s | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class io --tz -v --all 4 -t 10s | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class filesystem --tz -v --all 4 -t 10s | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
#stress-ng --temp-path /tmp/stress-tmp/ --class memory --tz -v --all 4 -t 10s | echo "$(date -d @$(date +%s.%3N)): Stressor Started" &
} 2> $DARSHAN_TMP/stress-ng.${PBS_JOBID}.err

START=$(date +%s.%N)
srun --mpi=pmi2 $@
END=$(date +%s.%N)

killall -2 stress-ng | echo "$(date -d @$(date +%s.%3N)): Stressor Killed"

DIFF=$(echo "$END - $START" | bc)
echo "The DiffOfTime = $DIFF"

# confirm files have been written to successfully
du -h /pscratch/<user>/haccTest/darshan*

# parse log with the dxt parser
$DARSHAN_PATH/bin/darshan-dxt-parser --show-incomplete $DARSHAN_LOGFILE > $DARSHAN_TMP/${PROG}.${PBS_JOBID}-dxt.darshan.txt
if [ $? -ne 0 ]; then
    echo "Error: failed to parse ${DARSHAN_LOGFILE} for dxt tracing" 1>&2
    exit 1
fi

# parse log with normal parser
$DARSHAN_PATH/bin/darshan-parser --all $DARSHAN_LOGFILE > $DARSHAN_TMP/${PROG}.${PBS_JOBID}.darshan.txt
if [ $? -ne 0 ]; then
    echo "Error: failed to parse ${DARSHAN_LOGFILE}" 1>&2
    exit 1
fi
```
Where:
- ``$DARSHAN_TMP=/pscratch/<user>/darshan-ldms-output``
- ``$PROG=HACC_pscratch_10``
- ``$PBS_JOB_ID=slurm id of current job``
- ``$DARSHAN_PATH=/projects/ovis/darshanConnector/common/darshan/build/install``

### Slurm Output
Below is a slurm output example for HACC-IO with 1 node, 10 million particles and 32 tasks:
```sh
cat /pscratch/<user>/darshan-ldms-output/17301901-HACC_pscratch_10.out
Tue Sep 26 14:14:57 MDT 2023: Stressor Started
-------- Aggregate Performance --------
 WRITE Checkpoint Perf: 1954.54 BW[MB/s] 12965306368 Bytes 6.32612 MaxTime[sec]
-------- Aggregate Performance --------
 READ Restart Perf: 8973.73 BW[MB/s] 12965306368 Bytes 1.37788 MaxTime[sec]
 CONTENTS VERIFIED... Success
Tue Sep 26 14:19:30 MDT 2023: Stressor Killed
The DiffOfTime = 272.390139881
306M    /pscratch/<user>/haccTest/darshan-Part00000000-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000001-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000002-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000003-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000004-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000005-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000006-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000007-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000008-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000009-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000010-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000011-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000012-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000013-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000014-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000015-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000016-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000017-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000018-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000019-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000020-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000021-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000022-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000023-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000024-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000025-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000026-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000027-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000028-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000029-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000030-of-00000032.data
306M    /pscratch/<user>/haccTest/darshan-Part00000031-of-00000032.data
```
## Data collected 

Each experiment will collect **Darshan-LDMS** and **LDMS system utilization data**.

# [IN PROGRESS] Experiments with IOR

We want to show how LDMS-Darshan logs can be used to detect I/O bottlenecks at runtime and to diagnose it in real time. We will prove it by running applications with and without stressors to show, for example, that a shared system can impact I/O performance.

- Benchmark: IOR
- ``` ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan```
- Run 5 experiments
  - Clean run
  - With stressors: IO, filesystem, memory and cpu
- Stressors:
  - Starting at the same time during all execution 
  - Running on a different core than IOR 
  - Pin one stressor to each core in the same node 
  - If run in different nodes set one rank per node
- Set same parameter - app deals with same amount of I/O for all iterations and among all ranks 
- Collecting files: Slurm, LDMS-Darshan logs, system usage logs
  
## Eclipse specs

- Model name: Intel(R) Xeon(R) CPU E5-2695 v4 @ 2.10GHz
- System Type: CTS-1
- Arch: x86_64
- Title: RHEL 7.9
- CPU(s): 72
- Nodes: 1488
- L1d cache: 32K
- L1i cache: 32K
- L2 cache: 256K
- L3 cache: 46080K
- NUMA node0 CPU(s): 0-17,36-53
- NUMA node1 CPU(s): 18-35,54-71
- CPU max MHz: 2101.0000
- CPU min MHz: 1200.0000
- Interconnect: QPI (Quick Path Interconnect)
- Total Memory: 264047956 kB

## Post-processing logs:

Add header to the csvs:
```bash
sed -i '1s/^/uid,exe,job_id,rank,ProducerName,file,record_id,module,type,max_byte,switches,flushes,cnt,op,pt_sel,irreg_hslab,reg_hslab,ndims,npoints,off,len,start,dur,total,timestamp\n/' 17324718-IOR_pscratch_22.csv
```

Create CSV from DXT:
```bash
# Remove headers
sed -i '/^#/d' $filename
# Remove multiple spaces and replace with one
cat $filename | tr -s ' ' > tmp.csv
# Replace space with comma
sed -e 's/\s\+/,/g' tmp.csv > $filename
sed -i '/^$/d' $filename

# Add header:
n,Module,Rank,Wt/Rd,Segment,Offset,Length,Start,End

cat file1 >> file2
```

## Install Darshan locally:

```sh
wget https://ftp.mcs.anl.gov/pub/darshan/releases/darshan-3.4.4.tar.gz
tar -xzvf darshan-3.4.4.tar.gz
mkdir build/ && mkdir build/logs
./prepare.sh && cd build/
../configure --with-log-path-by-env=LOGFILE_PATH_DARSHAN --prefix=/<path-to-darshan>/build/install --with-jobid-env=PBS_JOBID CC=mpicc && make && make install
```

To run IOR or other apps collecting traces:
```bash 
export LD_PRELOAD=/path-to-darshan-install/lib/libdarshan.so
export LOGFILE_PATH_DARSHAN=<path-to-darshan>/build/logs
./ior -i 6 -b 144k -t 24k -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan
```

Parse results to textual format:
```bash
darshan-parser $LOGFILE_PATH_DARSHAN/filename.darshan > $LOGFILE_PATH_DARSHAN/filename.txt
```

## Runs with different FS and ranks

1. 3 runs (17534968, 17534969, 17534976) with 32 ranks: ``short_runs/ folders``. Command: 

```bash
/projects/ovis/darshanConnector/apps/rhel9.7/ior/src/ior -i 6 -b 144k -t 24k -s 1024 -F -C -e -k -o /pscratch/spwalto/iorTest/darshan
```

2. 3 runs (17532847, 17532848, 17532849) with the output file writing to memory (i.e. tmp/) and 36 ranks attached to a core (i.e. --cpu-bind=v,RANK).

```bash
/projects/ovis/darshanConnector/apps/rhel9.7/ior/src/ior -i 6 -b 2m -t 1m -s 6 -F -C -e -k -o /tmp/tmp.dJNPwjm8QH
```

3. 3 runs (17533880, 17533919, 17533963) with the output file writing to pscratch filesystem and 36 ranks attached to a core (i.e. --cpu-bind=v,RANK).

```bash
/projects/ovis/darshanConnector/apps/rhel9.7/ior/src/ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan
``` 

## Analysis and Visualization

- Code for analyzing data and generating plots: [./analysis/](./analysis/)
- Figures in: [./figures/](./analysis/)
- Code for automatically identifying anomalies in: [./code/](./code/)