# Author: Ana Solorzano
#!/bin/bash

# Script to get machine information before running and experiment in a new machine

set +e # Avoid quick failing if some information is missing

title="Machine information"
inputfile=""
host="$(hostname | sed 's/[0-9]*//g' | cut -d'.' -f1)"
help_script()
{
    cat << EOF
Usage: $0 outputfile.txt
EOF
}
# Parsing options
while getopts "t:s:i:h" opt; do
    case $opt in
	h)
	    help_script
	    exit 4
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG"
	    help_script
	    exit 3
	    ;;
    esac
done

shift $((OPTIND - 1))
filedat=$1
if [[ $# != 1 ]]; then
    echo 'ERROR!'
    help_script
    exit 2
fi

# Preambule of the output file
echo "Title: $title" >> $filedat
echo "Date: $(eval date)" >> $filedat
echo "Author: $(eval whoami)" >> $filedat
echo "Machine: $(eval hostname)" >> $filedat
echo "File: $(eval basename $filedat)" >> $filedat
if [[ -n "$inputfile" ]]; 
then
    echo "Inputfile: $inputfile" >> $filedat
fi
echo " " >> $filedat 

echo "############################################" >> $filedat
# Collecting metadata
echo "MACHINE INFORMATION:" >> $filedat
echo "People logged:" >> $filedat
who >> $filedat
echo "############################################" >> $filedat

echo "DISK INFORMATION:" >> $filedat
echo "People logged:" >> $filedat
lsblk >> $filedat
echo "############################################" >> $filedat

# OUTPUT filename-htop.html
echo "COLLECTING HTOP INFO IN HTOP.HTML:" >> $filedat
echo q | htop | aha --black --line-fix > filename-htop.html
echo "############################################" >> $filedat

echo "ENVIRONMENT VARIABLES:" >> $filedat
env >> $filedat
echo "############################################" >> $filedat

echo "HOSTNAME:" >> $filedat
hostname >> $filedat
echo "############################################" >> $filedat

# OUTPUT filename-lstopo.xml
if [[ -n $(command -v lstopo) ]];
then
    echo "HWLOC-LS PHYSICAL:" >> $filedat
    lstopo -p --of console >> $filedat
    echo "############################################" >> $filedat

    echo "MEMORY HIERARCHY:" >> $filedat
    lstopo --of console >> $filedat
    lstopo filename-lstopo.xml
    echo "############################################" >> $filedat
fi

if [ -f /proc/cpuinfo ];
then
    echo "CPU INFO:" >> $filedat
    cat /proc/cpuinfo >> $filedat
    echo "############################################" >> $filedat
fi

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ];
then
    echo "CPU GOVERNOR:" >> $filedat
    ONLINECPUS=$(for CPU in $(find /sys/devices/system/cpu/ | grep cpu[0-9]*$); do [[ $(cat $CPU/online) -eq 1 ]] && echo $CPU; done | grep cpu[0-9]*$ | sed 's/.*cpu//')
    for PU in ${ONLINECPUS}; do
	     echo -n "CPU frequency for cpu${PU}: " >> $filedat
       cat /sys/devices/system/cpu/cpu${PU}/cpufreq/scaling_governor >> $filedat
    done
    echo "############################################" >> $filedat
fi

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ];
then
    echo "CPU FREQUENCY:" >> $filedat
    ONLINECPUS=$(for CPU in $(find /sys/devices/system/cpu/ | grep cpu[0-9]*$); do [[ $(cat $CPU/online) -eq 1 ]] && echo $CPU; done | grep cpu[0-9]*$ | sed 's/.*cpu//')
    for PU in ${ONLINECPUS}; do
	     echo -n "CPU frequency for cpu${PU}: " >> $filedat
	     cat /sys/devices/system/cpu/cpu${PU}/cpufreq/scaling_cur_freq >> $filedat
    done
    echo "############################################" >> $filedat
fi

if [ -f /usr/bin/cpufreq-info ];
then
    echo "CPUFREQ_INFO" >> $filedat
    cpupower frequency-info >> $filedat
    cpupower idle-info >> $filedat
    cpupower monitor >> $filedat
    echo "############################################" >> $filedat
fi

if [ -f /usr/bin/lspci ];
then
    echo "LSPCI" >> $filedat
    lspci >> $filedat
    echo "############################################" >> $filedat
fi

if [ -f /usr/bin/ompi_info ];
then
    echo "OMPI_INFO" >> $filedat
    ompi_info --all >> $filedat
    echo "############################################" >> $filedat
fi

if [ -f /sbin/ifconfig ];
then
    echo "IFCONFIG" >> $filedat
    /sbin/ifconfig >> $filedat
    echo "############################################" >> $filedat
fi

if [[ -n $(command -v nvidia-smi) ]];
then
    echo "GPU INFO FROM NVIDIA-SMI (IF EXISTS):" >> $filedat
    nvidia-smi -q >> $filedat
    echo "############################################" >> $filedat
fi 

if [ -f /proc/version ];
then
    echo "LINUX AND GCC VERSIONS:" >> $filedat
    cat /proc/version >> $filedat
    echo "############################################" >> $filedat
fi

if [[ -n $(command -v module) ]];
then
    echo "MODULES:" >> $filedat
    module list 2>> $filedat
    echo "############################################" >> $filedat
fi

echo "TCP PARAMETERS" >> $filedat
FILES="/proc/sys/net/core/rmem_max \
/proc/sys/net/core/wmem_max \
/proc/sys/net/core/rmem_default \
/proc/sys/net/core/wmem_default \
/proc/sys/net/core/netdev_max_backlog \
/proc/sys/net/ipv4/tcp_rmem \
/proc/sys/net/ipv4/tcp_wmem \
/proc/sys/net/ipv4/tcp_mem"

for FILE in $FILES; do
    echo "cat $FILE"
    cat $FILE
done >> $filedat
