# ldms-darshan-analysis

## Darshan-LDMS absolute timestamp

Run I/O benchmarks with system stressors to show that we can use the system timestamps collected by Darshan-LDMS to diagnose application bottlenecks.

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

Applications:
- HACC-IO
- MPI-IO

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
Where ``$DARSHAN_LOGFILE=/pscratch/<user>/darshan-ldms-output`` and ``$PROG=HACC_pscratch_10``


## Data collected 

Each experiment will collect **Darshan-LDMS** and **LDMS system utilization data**.
