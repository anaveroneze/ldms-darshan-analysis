# Before implementing in Python something more automatic, let's
# see which system information will be relevant to get insights on bottlenecks
# 1. Identify longer operations 
# 2. Identify long intervals between last read/write and a met operation open/close 
# 3. Identify distance between the first rank to finish and others
# 4. Identify long intervals between operations in the same rank

source("./analysis/initialization.R")
############################################################################
# Analysing IOR logs using Darshan-LDMS data:
# ./ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan
# Focus on the first iteration
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533880-IOR_pscratch.csv") %>%
    mutate(end = timestamp - min(timestamp), timestamp_start = timestamp - dur) %>%
    filter(end <= 53) %>%
    mutate(start = end - dur) %>%
    filter(module == "POSIX") 

min(df$timestamp_start) -> min_start
max(df$timestamp) -> max_end

############################################################################
# LUSTRE
############################################################################
df.lustre <- read_csv("./ior/eclipse/system/lustre/17533880-lustre_client.csv") %>%
    select(-brw_write.sum, -setattr, -truncate, -readdir, -brw_read.sum, -job_id, -component_id, -create, -flock, -llite, -dirty_pages_hits, -dirty_pages_misses, -app_id) %>%
    filter(timestamp <= max_end) %>% filter(fs_name == "pscratch")

df.lustre %>% head(3) %>% as.data.frame()

df.lustre %>% group_by(read_bytes.sum) %>% summarise(n=n()) %>% arrange(-read_bytes.sum)
df.lustre %>% group_by(write_bytes.sum) %>% summarise(n=n()) %>% arrange(-write_bytes.sum)
df.lustre %>% group_by(seek) %>% summarise(n=n()) %>% arrange(-seek)
df.lustre %>% group_by(fsync) %>% summarise(n=n()) %>% arrange(-fsync) 

df %>% 
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) + ggtitle("First iteration - 17533880") +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p0

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=fsync)) +
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Fsync operations", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p1

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=inode_permission)) +
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("inode_permission", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p2

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=seek)) +
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("seek", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p3

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=close)) + 
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Closes", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p4

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=open)) + 
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Opens", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p5

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=read_bytes.sum)) +
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("read_bytes", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p6

df.lustre %>% 
    mutate(time = timestamp - min(timestamp)) %>%
    ggplot(aes(x=time, y=write_bytes.sum)) + 
    geom_line() + geom_point() + my_theme() + 
    theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,53), breaks=seq(0,10000,2)) + 
    scale_y_continuous("write_bytes", expand=c(0,0)) +
    guides(fill=guide_legend(title="Operation")) -> p7

    ggsave(filename=paste("./figures/ior/lustre-17533880.png", sep=""), plot = p0/p5/p2/p7/p6/p1/p3/p4, height=15, width=8)


############################################################################
# MEMINFO
############################################################################
df.meminfo <- read_csv("./ior/eclipse/system/meminfo/17533880-meminfo.csv") %>%
    filter(timestamp <= max_end) 

############################################################################
# PROCSTAT
############################################################################
df.procstat <- read_csv("./ior/eclipse/system/procstat/17533880-procstat_72.csv") %>%
    filter(timestamp <= max_end) 

# df.procstat


