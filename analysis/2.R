source("./analysis/initialization.R")

df <- read_csv("./ior/eclipse/darshan-ldms-output/csv/17438620-IOR_pscratch_none.csv")
df 

df %>% group_by(module) %>%
    summarise(n=n())

df %>% group_by(op) %>%
    summarise(n=n())

as_datetime(min(df$timestamp), tz="America/Denver")
as_datetime(max(df$timestamp), tz="America/Denver")

df %>%
    mutate(end = start + dur) %>%
    ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
    geom_rect(linewidth=0.1) + 
    my_theme() + theme(panel.grid.major.x=element_blank()) +
    scale_x_continuous("Execution Time (seconds)", expand=c(0,0)) + 
    scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,32,2)) +
    guides(fill=guide_legend(title="Operation")) -> p

    ggsave(filename=paste("./figures/ior-darshan-ldms.png", sep=""),
        plot = p, height=3, width=8)

# as_datetime(min(df$timestamp), tz="America/Denver")
# as_datetime(max(df$timestamp), tz="America/Denver")
# df %>% head(10) %>% as.data.frame()

# # Let's understand what I/O operations IOR is doing
# df %>% group_by(op) %>% summarise(n=n())
# df %>% group_by(type) %>% summarise(n=n())
# df %>% group_by(module) %>% summarise(n=n())
# df %>% group_by(module) %>% summarise(n=n())

# df %>%
#     filter(module == "POSIX") %>%
#     mutate(start = timestamp - min(timestamp)) %>% select(timestamp, rank, type, max_byte, dur, start) -> df 

# write_parquet(df, "./ior/eclipse/darshan-ldms/all-short.parquet")

# df <- read_parquet("./ior/eclipse/darshan-ldms/all-short.parquet")
# min(df$start)
# max(df$start)

# df %>% filter(rank ==9) %>% head(50) %>% arrange(start) %>% as.data.frame() 

# df %>%
#     mutate(end = start + dur) %>% 
#     filter(start <= 3.3) %>%
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4)) +
#     geom_rect(linewidth=0.1, fill="blue") + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="none") +
#     scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10,0.2)) + 
#     scale_y_continuous("Rank ID", expand=c(0,0), lim=c(0, NA), breaks=seq(0,16,2)) +
#     ggtitle("Write operations captured with Darshan-LDMS") +
#     guides(fill=guide_legend(title="Operation")) -> p

#     ggsave(filename=paste("./figures/ior-darshan-ldms-filter.png", sep=""),
#     plot = p, height=5, width=20)

# df <- read_csv("./ior/eclipse/darshan-logs/darshan.csv")
# df %>% group_by(Segment) %>% summarise(n=n()) %>% arrange(-n)
# df %>%
#     filter(Module == "X_POSIX") %>%
#     ggplot(aes(xmin=Start, xmax=End, ymin=Rank-0.4, ymax=Rank+0.4)) +
#     geom_rect(linewidth=0.1, fill="blue") + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="none") +
#     scale_x_continuous("Execution Time (seconds)", expand=c(0,0), breaks=seq(0,10,0.2)) + 
#     scale_y_continuous("Rank ID", expand=c(0,0), lim=c(0, NA), breaks=seq(0,16,2)) +
#     ggtitle("Write operations captured with Darshan") +
#     guides(fill=guide_legend(title="Operation")) -> p

#     ggsave(filename=paste("./figures/ior-darshan.png", sep=""),
#     plot = p, height=5, width=20)


