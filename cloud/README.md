# Collecting I/O information in the cloud

I am exploring which system usage information can be captured in an AWS instance, if we can collect information using I/O benchmarks and then if we can collect information using Darshan-LDMS.

- Instance type: t2.micro (free tier eligible) with Ubuntu as OS
- Variability in the results: 
  - AWS instances run as VMs, so I/O resources as disk and network are shared among multiple VMs on the same physical host. 
  - We cannot obtain for sure the amount of variability
  - But we can capture an estimative by measuring I/O system utilization and running an I/O intensive benchmark - the difference indicates I/O usage unrelated to my user execution
- Preparing the environment:

```
sudo apt update
sudo apt upgrade
sudo apt install python3-pip
sudo apt-get install -y aha

pip install boto3==1.17.81
pip install ratatouille
pip install rsa

sudo apt install openmpi-bin openmpi-common libopenmpi-dev
sudo apt install sysstat
sudo apt install cmake

iostat
vmstat

export PATH="$HOME/.local/bin:$PATH"

```

## System monitoring, profiling & other tools

I am using lstopo and basic UNIX commands in a script to get all system information possible. You can run as: 
    
```sh
chmod +x get_sys_info.sh
./get_sys_info.sh outputfile.txt
```    

I am using the open-source tool **Ratatouille**, which uses psutils library to collect information from UNIX commands using Python. It can easily be launched before the execution to collect info in the background: https://github.com/Ezibenroc/ratatouille. You can run as: 

```sh
ratatouille collect -t 1 cpu_freq cpu_power cpu_load cpu_stats fan_speed memory_usage network temperature ratatouille_output.txt
```  

*You need to interrupt the execution with CTRL+C:*

It can't capture information about power and frequency:

```
WARNING: Power monitoring unavailable, could not read intel-rapl files
WARNING: CPU frequency unavailable, could not read cpufreq files
```

It captured:
```
hostname,timestamp,memory_available_percent,memory_available,cpu_load,bytes_sent_eth0,bytes_recv_eth0,bytes_sent_lo,bytes_recv_lo,ctx_switches,interrupts,soft_interrupts
ip-172-31-26-212,2024-04-15 16:16:16.101683,62.2,619597824,1.0,0.0,207.42051087702347,0.0,0.0,660386,362755,346489
ip-172-31-26-212,2024-04-15 16:16:17.102769,62.2,619597824,0.0,0.0,0.0,0.0,0.0,660404,362779,346501
ip-172-31-26-212,2024-04-15 16:16:18.103883,62.2,619597824,0.0,0.0,0.0,0.0,0.0,660433,362815,346519
ip-172-31-26-212,2024-04-15 16:16:19.104984,62.2,619597824,0.0,0.0,0.0,0.0,0.0,660454,362843,346532
```

What these information represents?

```
- timestamp: it is collecting information at a granularity of 1 second, this can be modified
- memory_available_percent: over the total memory
- memory_available: in bytes
- cpu_load: % load of the CPUs
- bytes_sent_eth0: outbound traffic via ethernet connection
- bytes_recv_eth0: outbound traffic via ethernet connection
- bytes_sent_lo: outbound traffic via loopback interface
- bytes_recv_lo
- ctx_switches: # of context switches - CPU changing from one process to another. It can impact the performance of the system.
- interrupts: # of interrupts - sign sent by hardware indicating that an event needs immediate atention
- soft_interrupts : # of soft interrupts since boot - sign sent by software (tipically the OS) indicating that an event needs immediate atention
```

## Benchmarks

    - Parallel I/O benchmarks: HACC-IO
    - Might need to export OMP_NUM_THREADS as the number of threads per process. OMP_NUM_THREADS=2

### HACC-IO ✔

    Uses the Hardware Accelerated Cosmology Code (HACC) simulation to explore I/O access. Basicallu uses N-body techniques to simulate the formation of structure in collisionless fluids under the influence of gravity in an expanding universe.

    - https://www.vi4io.org/tools/benchmarks/hacc_io
    - I/O performance benchmark using N-body simulations
    - The input parameter determines the number of particles used in the HACC experiment - more particles longer the execution
    - Parallelized with MPI
    - Output shows the bandwidth per process, the bytes per process and the maximum execution time
    - Each process writes the number of particles * 38 bytes + 24MB header

    Install and run:

```sh
cd ./benchmarks 
git clone https://github.com/glennklockwood/hacc-io.git
mv hacc-io/ haccio/
cd haccio/
make clean
make CXX=mpicxx

# Run for
mpirun -np 2 ./hacc_io 5000000 outputfile
```

    Experiments:
    - Particles per process: 10,000,000 ~(380 MB + 24MB) and 5,000,000 ~(190MB + 24MB) 
    - Processes: 1, 2, 4, 8, 16
    
    Dataset format:
    - rep;proc_total;proc_id;op;bw
      1;64;0;write/read;799.564
    - 
    Results:
    - Plot execution time for different number of processes
    - Plot the max bandwidth (Mb/S) per process (X) processes for write and read with sd
    - Plot the CDF of the experiments for write/read (X) processes

<!-- ### CORAL-2 - VPIC ✔

    Particle physics simulation developed by Los Alamos National Lab, using 2D, 2D or 3D array that explore I/O access.
    
    - https://github.com/lanl/vpic
    - It creates a file, write 8 random float variables and closes the file
    - Parallelized with MPI and threads -->


<!-- ```sh
git clone https://github.com/lanl/vpic.git
cd vpic
mkdir build
cd build
../arch/reference-Release
make
# Build the input deck
./bin/vpic ../sample/harris 
# Number of threads per MPI rank
mpirun -n N ./harris.Linux --tpp 8
```

    Results:
    - Bandwidth (MB/s)
    - Execution time -->

## Running Experiments

After installing the benchmarks and the necessary packages/tool/libraries in the environment you can run the application using the Python script:

```
python3 get_usage_info.py -rep 1 -app haccio
```

Copy results locally:

```
scp -r -i ~/.ssh/ana.pem ec2-user@ec2-INSTACE-IP.compute-1.amazonaws.com:/home/ubuntu/* .
```

## Output

Each repetition of each application generates 3 files, containing the output information of the psutil I/O collection, the output of the benchmark, and the information collected by ratatouille with other information about the system usage:

Execution for HACCIO:


```
ratatouille.csv

hostname,timestamp,bytes_sent_eth0,bytes_recv_eth0,bytes_sent_lo,bytes_recv_lo,ctx_switches,interrupts,soft_interrupts,memory_available_percent,memory_available,cpu_load
ip-172-31-95-23,2024-04-15 19:29:35.086611,233.26987248176164,102.79689295806446,2986.0520540991606,2986.0520540991606,1558571,1161407,785412,7.0,69341184,57.0
ip-172-31-95-23,2024-04-15 19:29:36.085363,0.0,0.0,0.0,0.0,1559998,1163289,786287,8.099999999999994,80687104,11.3
ip-172-31-95-23,2024-04-15 19:29:37.085468,0.0,0.0,0.0,0.0,1560845,1164757,786977,6.700000000000003,66654208,7.1
ip-172-31-95-23,2024-04-15 19:29:38.086574,0.0,0.0,0.0,0.0,1561493,1166074,787597,7.200000000000003,71229440,6.2
ip-172-31-95-23,2024-04-15 19:29:39.087630,0.0,0.0,0.0,0.0,1562164,1167430,788222,7.700000000000003,76476416,7.1
ip-172-31-95-23,2024-04-15 19:29:40.088716,0.0,0.0,0.0,0.0,1562840,1168824,788855,8.200000000000003,81403904,7.1
ip-172-31-95-23,2024-04-15 19:29:41.089477,0.0,0.0,0.0,0.0,1563434,1170225,789478,6.700000000000003,66658304,7.1
ip-172-31-95-23,2024-04-15 19:29:42.090550,0.0,0.0,0.0,0.0,1564077,1171608,790093,7.099999999999994,70451200,7.1
ip-172-31-95-23,2024-04-15 19:29:43.091611,89.90298726073692,75.91807813128895,0.0,0.0,1564905,1173145,790795,5.700000000000003,56786944,11.0
ip-172-31-95-23,2024-04-15 19:29:44.092763,0.0,0.0,155.67145830418858,155.67145830418858,1567441,1178762,793483,69.9,696107008,69.7
ip-172-31-95-23,2024-04-15 19:29:45.093509,0.0,0.0,0.0,0.0,1567483,1178828,793511,69.9,695816192,0.0
ip-172-31-95-23,2024-04-15 19:29:46.094584,0.0,0.0,0.0,0.0,1567787,1179140,793737,69.6,693071872,2.9
ip-172-31-95-23,2024-04-15 19:29:47.094686,189.9820177886338,0.0,0.0,0.0,1568027,1179362,793878,69.8,694755328,2.0
```

```
output.txt

-------- Aggregate Performance --------
 WRITE Checkpoint Perf: 69.0156 BW[MB/s] 595165824 Bytes 8.22415 MaxTime[sec] 
--------------------------------------------------------------------------
Primary job  terminated normally, but 1 process returned
a non-zero exit code. Per user-direction, the job has been aborted.
--------------------------------------------------------------------------
--------------------------------------------------------------------------
mpirun noticed that process rank 0 with PID 0 on node ip-172-31-95-23 exited on signal 9 (Killed).
--------------------------------------------------------------------------
Execution time: 12.112745523452759
```

```
output-io.txt

Time,DiskReads,DiskWrites,NetBytesSent,NetBytesRecv
1713209373.934851,9089163264,13952979968,3745928,283606522
1713209374.9368188,9106014208,13976638464,3750185,283610699
1713209375.9397368,9107496960,14087963648,3750185,283610699
1713209376.941989,9107910656,14152107008,3750185,283610699
1713209377.9441845,9107918848,14216201216,3750185,283610699
1713209378.9462128,9107927040,14280328192,3750185,283610699
1713209379.9900317,9107935232,14347125760,3750185,283610699
1713209380.9920225,9107939328,14411338752,3750185,283610699
1713209381.99401,9108733952,14475408384,3750185,283610699
1713209382.996921,9109012480,14539658240,3750275,283610775
1713209384.0208635,9231912960,14553748480,3750431,283610931
1713209385.0237753,9233043456,14553748480,3750431,283610931
1713209386.0254126,9239474176,14553748480,3750431,283610931
```

Looking at HACCIO output:
- 595,165,824 bytes written
- bw: 69.0156MB/s
- Maximum Time: 8.22415 seconds

Looking at the I/O output:
- The monitoring starts at 13952979968 bytes until 14553748480 bytes
- (13952979968 - 14553748480) = 600,768,512 bytes during the HACCIO execution, near the 595MB reported in the log!

## [TO-DO] Installing LDMS-Darshan and run an application
## [TO-DO] Use AWS CloudWatch https://aws.amazon.com/cloudwatch/