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
- 

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

2. HACCIO with 100.000.000 particles and specific classes running in background for 10 seconds:
```sh
stress-ng --class cpu --tz -v --all 4 -t 10s & 
stress-ng --class cpu-cache --tz -v --all 4 -t 10s &
stress-ng --class io --tz -v --all 4 -t 10s &
stress-ng --class filesystem --tz -v --all 4 -t 10s &
stress-ng --class memory --tz -v --all 4 -t 10s &
```

Run one stressor for each run, so a total of 10 experiments + 2 normal executions (no stressors).

