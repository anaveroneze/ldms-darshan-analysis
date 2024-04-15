import subprocess, os, time, io, sys, argparse, threading
import psutil

# Global definitions
nodes = [1, 2]
proc_1node = [1]
threads = [1, 2, 4, 8]
RATA_ARGS = " cpu_load cpu_stats fan_speed memory_usage network temperature "

def monitor_io(stop_event, output_file, interval=0.2):
    with open(output_file, 'w') as f:
        f.write(f"Time,DiskReads,DiskWrites,NetBytesSent,NetBytesRecv\n")
        while not stop_event.is_set():
            disk_io = psutil.disk_io_counters()
            net_io = psutil.net_io_counters()
            f.write(f"{time.time()},{disk_io.read_bytes},{disk_io.write_bytes},{net_io.bytes_sent},{net_io.bytes_recv}\n")
            f.flush()
            time.sleep(interval)

def create_ouput(dir_name):
    print(dir_name)
    subprocess.call("mkdir -p output/" + dir_name, shell=True)

# HACC-IO #######################################################
def set_haccio(rep, nodes):

    particles = ["10000000", "15000000"]

    # Create output directory
    dir_name="haccio/" + str(rep) + "/"
    create_ouput(dir_name)

    for p in proc_1node:
        for part in particles:
            runline="mpirun -n " + str(p) + " ./haccio/hacc_io " + part + " outputfile" + str(rep)
            print(runline)
            create_ouput(dir_name + "1-" + str(p) + "-" + str(part))
            run_app(runline, rep, dir_name + "1-" + str(p) + "-" + str(part))

# VPIC #########################################################
def set_vpic(rep, nodes):

    # Create output directory
    dir_name="vpic/" + str(rep) + "/"
    create_ouput(dir_name)
    
    for p in proc_1node:
        runline="mpirun -n " + str(p) + " ./vpic/build/generic.Linux "
        print(runline)
        create_ouput(dir_name + "1-" + str(p))
        run_app(runline, rep, dir_name + "1-" + str(p))

# VPIC #########################################################
def set_vpic_serial(rep, nodes):

    # Create output directory
    dir_name="vpic-serial/" + str(rep) + "/"
    create_ouput(dir_name)
    
    for t in threads:
        runline="./vpic-serial/build/harris.Linux --tpp " + str(t)
        print(runline)
        create_ouput(dir_name + str(t))
        run_app(runline, rep, dir_name + str(t))

# Run Ratatouille in the background and the script runline
def run_app(runline, rep, dir, rata_time=1):

    stop_event = threading.Event()
    # Define ratatouille file and stdout + stderr file
    RATA_FILENAME = "output/" + dir + "/ratatouille" + ".csv"
    OUTPUT_FILENAME = "output/" + dir + "/output" + ".txt"
    fwrite = open(OUTPUT_FILENAME, "wb")
    fwrite.flush()
    os.fsync(fwrite.fileno())

    # Collect information every 1 seconds
    subprocess.call("ratatouille collect -t " + str(rata_time) + " " + RATA_ARGS + RATA_FILENAME + " &", shell=True)
    subprocess.call("echo $! > rata_pid", shell=True)

    # Collect other I/O information:
    OUTPUT_IO_FILENAME = "output/" + dir + "/output-io" + ".txt"
    monitor_thread = threading.Thread(target=monitor_io, args=(stop_event, OUTPUT_IO_FILENAME, rata_time))
    monitor_thread.start()

    # RUN THE EXPERIMENT ######################################
    start_time = time.time()
    subprocess.call(runline, shell=True, stdout=fwrite, stderr=fwrite)
    execution_time = time.time() - start_time
    # ########################################################

    # Stop the psutil io collection thread
    stop_event.set()
    monitor_thread.join()

    # Kill ratatouille execution
    subprocess.call("killall -2 ratatouille", shell=True)    

    # Write execution time in file and close it
    fwrite.write("Execution time: ".encode())
    fwrite.write(str(execution_time).encode())
    fwrite.close()

def check_ratatouille():
    subprocess.call("ratatouille collect -t 1 cpu_freq cpu_power cpu_load cpu_stats fan_speed memory_usage network temperature temp_output_file", shell=True)

def main():

    parser = argparse.ArgumentParser(description="Running selected benchmark or all: ./run.py BENCH")
    parser.add_argument('-app', type=str, help='Name of the application', default="all")
    parser.add_argument('-n', type=int, help='Number of nodes', default=1)
    parser.add_argument('-rep', type=int, help='Experiments repetitions', default=2)
    parser.add_argument('-ratatouille', type=int, help='Check ratatouille accesses', default=0)

    args = parser.parse_args()
    app_name = args.app 

    # Check ratatouille accesses
    if(args.ratatouille):
        check_ratatouille()
        exit()

    # Create output directory
    subprocess.call("mkdir -p output", shell=True)
    
    # Get environment info 
    FILE_GET_INFO="output/get_sys_info.txt"
    subprocess.call("bash get_sys_info.sh " + FILE_GET_INFO, shell=True)

    # For all experiments
    for i in range(0, args.rep):

        # Call script to run all benchmarks
        if(app_name == "all"):
            set_haccio(i, args.n)
            set_vpic(i, args.n)
            set_vpic_serial(i, args.n)

        else:
            print(app_name)
            for app in app_name.split(","):
                if(app == "haccio"):
                    set_haccio(i, args.n)
                if(app == "vpic"):
                    set_vpic(i, args.n)

if __name__== "__main__":
    main()