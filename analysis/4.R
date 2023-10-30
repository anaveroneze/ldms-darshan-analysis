source("./analysis/initialization.R")


############################################################################
# Analysing Darshan-LDMS information
# ./ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan
############################################################################
# Repetition 1
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533880-IOR_pscratch.csv") %>%
    mutate(start = timestamp - min(timestamp)) %>%
    mutate(end = start + dur) %>%
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints,
        -record_id) %>%
    filter(module == "POSIX") 

df 
min(df$start)
max(df$end)
# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

max(df$end) -> max_end
# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max_end, color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533880.png", sep=""),
        plot = p, height=2, width=8)

df %>% 
    filter(end <= 55) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,NA), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,2)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533880-zoom.png", sep=""),
        plot = p, height=3, width=8)

df %>%  
    filter(end <= 18) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,NA), breaks=seq(0,10000,1)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,2)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533880-zoom1.png", sep=""),
        plot = p, height=3, width=8)

df %>%  
    filter(end <= 54) %>%
    filter(start >= 49.5) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,2)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533880-zoom2.png", sep=""),
        plot = p, height=3, width=8)

df %>%  
    filter(end <= 50) %>%
    filter(start >= 49.5) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.1)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,2)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533880-zoom2.5.png", sep=""),
        plot = p, height=3, width=8)

df %>% filter(end <= 18) %>%
    group_by(op, rank) %>% summarise(n=n(), max_dur= max(dur), min_dur = min(dur)) %>% arrange(-max_dur)

# df %>% filter(op %in% c("read", "write")) %>% group_by(rank, op) %>% 
#     summarise(n=n()/6, sum.mib = round((sum(len)/6)/100000, 3), 
#         mib.persec = (sum(len)/1000000)/sum(dur)/6, sum.dur = round(sum(dur), 3)) %>% as.data.frame()
# df %>% filter(op %in% c("read", "write")) %>% group_by(rank, op) %>% 
#     summarise(mib.persec = ((sum(len)/1000000) / sum(dur)) /6, sum.dur = round(sum(dur), 3)/6) %>%
#     as.data.frame() %>% print() %>%
#     group_by(op) %>% 
#         summarise(mean.per.it = mean(sum.dur), 
#         mean.mib.persec = mean(mib.persec)) %>% as.data.frame()

# Relevant information
df %>% distinct(module) 
df %>% distinct(off) 
df %>% distinct(len) 
df %>% distinct(type) 
df %>% distinct(max_byte) 
df %>% distinct(switches) 

############################################################################
# Repetition 2
############################################################################
df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533919-IOR_pscratch.csv") %>%
    mutate(start = timestamp - min(timestamp)) %>%
    mutate(end = start + dur) %>%
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints, -record_id) %>%
    filter(module == "POSIX") 

df 
min(df$start)
max(df$end)
# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

max(df$end) -> max_end
# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max_end, color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533919.png", sep=""),
        plot = p, height=2, width=8)

df %>% 
    filter(start >=14) %>%
    filter(end <=18.5) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533919-zoom.png", sep=""),
        plot = p, height=3, width=8)

df %>% filter(start >=14) %>%
    filter(end <=18.5) %>%
    group_by(op, rank) %>% summarise(max_dur= max(dur), min_dur = min(dur)) %>% arrange(-max_dur)


############################################################################
# Repetition 3
############################################################################

df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17533963-IOR_pscratch.csv") %>%
    mutate(start = timestamp - min(timestamp)) %>%
    mutate(end = start + dur) %>%
    select(-exe, -uid, -ProducerName, -file, -job_id, -pt_sel, -irreg_hslab, -reg_hslab, -ndims, -npoints, -record_id) %>%
    filter(module == "POSIX") 

df 
min(df$start)
max(df$end)
# Total info
df %>% filter(op %in% c("read", "write")) %>% group_by(op) %>% 
    summarize(n=n(), total_gib = sum(len)/1000000000, total_dur = sum(dur), mean_dur_per_rank_it = sum(dur)/(36*6))

max(df$end) -> max_end
# Plotting information...
df %>% filter(op %in% c("read", "write")) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + geom_vline(xintercept = max_end, color = "red", size=0.5) +
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,326), breaks=seq(0,10000,20)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms-17533963.png", sep=""),
        plot = p, height=2, width=8)