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

# Testing:
mpirun -np 2 ./hacc_io 100000 outputfile
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

# Testing
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

# Testing
# Build the input deck
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

# Testing
python3 ./candle/Pilot3/P3B3/p3b3_baseline_keras2.py
```

## Stressors

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

## Data collected

- Darshan-LDMS 
- LDMS system utilization data

