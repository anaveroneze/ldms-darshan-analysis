source("./analysis/initialization.R")
############################################################################
# Analysing IOR logs for Darshan-LDMS and Darshan-DXT to check if it is collecting all:
# ./ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan

############################################################################
# Repetition 1 - Darshan-LDMS
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533880-IOR_pscratch.csv") %>%
    mutate(end = timestamp - min(timestamp)) %>%
    mutate(start = end - dur) %>%
    # Remove columns that do not vary
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints, -record_id) %>%
    filter(module == "POSIX") 

df %>% filter(op %in% c("read", "write"))
min(df$start)
max(df$end)

# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max(df$end), color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) + ggtitle("Darshan-LDMS 17533880") +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p1

############################################################################
# Repetition 1 - Darshan-DXT
############################################################################
df.dxt <- read_csv("./ior/eclipse/darshan-logs/csv/IOR_pscratch.17533880-dxt.darshan.csv") %>%
    mutate(dur = End-Start) 

df.dxt 
min(df.dxt$Start)
max(df.dxt$End)

df.dxt %>%
    ggplot(aes(xmin=Start, xmax=End, ymin=Rank-0.4, ymax=Rank+0.4, fill=`Wt/Rd`)) +
    geom_rect(linewidth=0.1) + ggtitle("Darshan-DXT 17533880") +
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p2

    ggsave(filename=paste("./figures/ior/17533880.png", sep=""), plot = p1/p2, height=5, width=8)

############################################################################
############################################################################
############################################################################
# Repetition 2 - Darshan-LDMS
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533919-IOR_pscratch.csv") %>%
    mutate(end = timestamp - min(timestamp)) %>%
    mutate(start = end - dur) %>%
    # Remove columns that do not vary
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints, -record_id) %>%
    filter(module == "POSIX") 

df %>% filter(op %in% c("read", "write"))
min(df$start)
max(df$end)

# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max(df$end), color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) + ggtitle("Darshan-LDMS 17533919") +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p1

############################################################################
# Repetition 2 - Darshan-DXT
############################################################################
df.dxt <- read_csv("./ior/eclipse/darshan-logs/csv/IOR_pscratch.17533919-dxt.darshan.csv") %>%
    mutate(dur = End-Start) 

df.dxt 
min(df.dxt$Start)
max(df.dxt$End)

df.dxt %>%
    ggplot(aes(xmin=Start, xmax=End, ymin=Rank-0.4, ymax=Rank+0.4, fill=`Wt/Rd`)) +
    geom_rect(linewidth=0.1) + ggtitle("Darshan-DXT 17533919") +
    my_theme() + theme(panel.grid.major.x=element_blank()) + geom_vline(xintercept = max(df$end), color = "red", size=0.5) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p2

    ggsave(filename=paste("./figures/ior/17533919.png", sep=""), plot = p1/p2, height=5, width=8)

############################################################################
############################################################################
############################################################################
# Repetition 3 - Darshan-LDMS
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533963-IOR_pscratch.csv") %>%
    mutate(end = timestamp - min(timestamp)) %>%
    mutate(start = end - dur) %>%
    # Remove columns that do not vary
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints, -record_id) %>%
    filter(module == "POSIX") 

df %>% filter(op %in% c("read", "write"))
min(df$start)
max(df$end)

# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max(df$end), color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) + ggtitle("Darshan-LDMS 17533963") +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p1

############################################################################
# Repetition 3 - Darshan-DXT
############################################################################
df.dxt <- read_csv("./ior/eclipse/darshan-logs/csv/IOR_pscratch.17533963-dxt.darshan.csv") %>%
    mutate(dur = End-Start) 

df.dxt 
min(df.dxt$Start)
max(df.dxt$End)

df.dxt %>%
    ggplot(aes(xmin=Start, xmax=End, ymin=Rank-0.4, ymax=Rank+0.4, fill=`Wt/Rd`)) +
    geom_rect(linewidth=0.1) + ggtitle("Darshan-DXT 17533963") +
    my_theme() + theme(panel.grid.major.x=element_blank()) + geom_vline(xintercept = max(df$end), color = "red", size=0.5) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p2

    ggsave(filename=paste("./figures/ior/17533963.png", sep=""), plot = p1/p2, height=5, width=8)

############################################################################
############################################################################
