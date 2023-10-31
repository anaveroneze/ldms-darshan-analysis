source("./analysis/initialization.R")
############################################################################
# Analysing IOR logs using Darshan-LDMS data:
# ./ior -i 6 -b 4m -t 2m -s 1024 -F -C -e -k -o /pscratch/user/iorTest/darshan
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
df %>% 
    filter(end <= 58) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) + ggtitle("First iteration - Darshan-LDMS 17533880") +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), lim=c(0,NA), breaks=seq(0,10000,2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p1

df %>% 
    filter(start >= 12.6) %>%
    filter(end <= 16.5) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + ggtitle("Zoom end of writes") +
    my_theme() + theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.2)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p2

df %>% 
    filter(start >= 19.5) %>%
    filter(start <= 19.70) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + ggtitle("Zoom beginning of reads") +
    my_theme() + theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.01)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p3 

df %>% 
    filter(start >= 50) %>%
    filter(end <= 58.3) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + ggtitle("Zoom end of reads") +
    my_theme() + theme(panel.grid.major.x=element_blank()) + 
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10000,0.3)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,36,4)) +
    guides(fill=guide_legend(title="Operation")) -> p4

    ggsave(filename=paste("./figures/ior/darshan-ldms-17533880.png", sep=""), plot = p1/p2/p3/p4, height=10, width=8)

