source("./analysis/initialization.R")

# read_csv("hacc-io/eclipse/darshan-ldms/csv/17210641-HACC_pscratch_100_none.csv") -> df_none
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17209783-HACC_pscratch_100_io.csv") -> df_io 
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17209771-HACC_pscratch_100_cpu.csv") -> df_cpu
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17209778-HACC_pscratch_100_cpu_cache.csv") -> df_cpu_cache
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17209808-HACC_pscratch_100_fs.csv") -> df_fs
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17218965-HACC_pscratch_100_mem.csv") -> df_mem

# df_none %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - No stressors") +
#     guides(fill=guide_legend(title="Length (Bytes)")) -> p

#     ggsave(filename=paste("./HACC_pscratch_100_none.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_io %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank()) +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - I/O stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) +
#     theme(legend.position="top") -> p

#     ggsave(filename=paste("./17209783-HACC_pscratch_100_io.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_cpu %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - CPU stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) -> p

#     ggsave(filename=paste("./17209771-HACC_pscratch_100_cpu.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_cpu_cache %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - CPU cache stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) -> p

#     ggsave(filename=paste("./17209778-HACC_pscratch_100_cpu_cache.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_fs %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - File System stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) -> p

#     ggsave(filename=paste("./17209808-HACC_pscratch_100_fs.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_mem %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 10 million particles - Memory stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) -> p

#     ggsave(filename=paste("./17218965-HACC_pscratch_100_mem.png", sep=""),
#     plot = p, height=2.5, width=6)

# #################################################
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17210635-HACC_pscratch_50_none.csv") -> df_none
# read_csv("hacc-io/eclipse/darshan-ldms/csv/17209746-HACC_pscratch_50_io.csv") -> df_io 
# df_none %>% group_by(len) %>% summarize(n=n())

# df_none %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank()) +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 5 million particles - No stressors") +
#     guides(fill=guide_legend(title="Length (Bytes)")) +
#     theme(legend.position="top") -> p

#     ggsave(filename=paste("./17210641-HACC_pscratch_50_none.png", sep=""),
#     plot = p, height=2.5, width=6)

# df_io %>%
#     mutate(start = timestamp - min(timestamp)) %>%
#     mutate(end = start + dur) %>% 
#     ggplot(aes(xmin=start, xmax=end, ymin=rank-0.4, ymax=rank+0.4, fill=len)) +
#     geom_rect(linewidth=0.1) + 
#     my_theme() + theme(panel.grid.major.x=element_blank()) +
#     scale_x_continuous("Execution Time (s)", expand=c(0,0)) + 
#     scale_y_continuous("Rank", expand=c(0,0), lim=c(0, NA)) +
#     scale_size(range = c(0.2, 5)) +
#     ggtitle("HACC-IO 5 million particles - I/O stressor") +
#     guides(fill=guide_legend(title="Length (Bytes)")) +
#     theme(legend.position="top") -> p

#     ggsave(filename=paste("./17209746-HACC_pscratch_50_io.png", sep=""),
#     plot = p, height=2.5, width=6)

#################################################
# PROCSTAT FOR THE IO STRESSOR
read_csv("hacc-io/eclipse/darshan-ldms/csv/17210641-HACC_pscratch_100_none.csv") -> df_none_ldms
read_csv("hacc-io/eclipse/darshan-ldms/csv/17209783-HACC_pscratch_100_io.csv") -> df_io_ldms

df_none_ldms %>% 
    mutate(min_time = min(timestamp),
        max_time = max(timestamp)) %>% head(1) -> df_none_time 
df_io_ldms %>% 
    mutate(min_time = min(timestamp),
        max_time = max(timestamp)) %>% head(1)  -> df_io_time 

read_csv("hacc-io/eclipse/system/procstat/17210641-procstat.csv") -> df_none
read_csv("hacc-io/eclipse/system/procstat/17209783-procstat.csv") -> df_io 

df_none
df_none %>%
    filter(timestamp >= df_none_time$min_time) %>%
    filter(timestamp <= df_none_time$max_time) %>%
    group_by() %>%
    summarize(sum_iowait = sum(iowait), user_sum = sum(user), sys_sum = sum(sys))

df_io %>%
    filter(timestamp >= df_io_time$min_time) %>%
    filter(timestamp <= df_io_time$max_time) %>%
    group_by() %>%
    summarize(sum_iowait = sum(iowait), user_sum = sum(user), sys_sum = sum(sys))



read_csv("hacc-io/eclipse/system/dstat/17210641-dstat.csv") -> df_none
read_csv("hacc-io/eclipse/system/dstat/17209783-dstat.csv") -> df_io 

df_none %>%
    filter(timestamp >= df_none_time$min_time) %>%
    filter(timestamp <= df_none_time$max_time) %>%
    group_by() %>%
    summarize(sum_writebytes = sum(write_bytes))

df_io %>%
    filter(timestamp >= df_io_time$min_time) %>%
    filter(timestamp <= df_io_time$max_time) %>%
    group_by() %>%
    summarize(sum_writebytes = sum(write_bytes))

















    # mutate(t = timestamp - min(timestamp)) %>%
    # mutate(proc = component_id - min(component_id)) %>%
    # ggplot(aes(x=t, y=ioctl), fill="blue") +
    # geom_point(linewidth=0.1) + 
    # my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
    # scale_x_continuous("Timestamp", expand=c(0,0)) + 
    # scale_y_continuous("Component ID", lim=c(0, NA)) +
    # guides(color=guide_legend(title="I/O Wait")) +
    # scale_size(range = c(0.2, 5)) +
    # ggtitle("HACC-IO 10 million particles - No stressors") +
    # guides(fill=guide_legend(title="Length (Bytes)")) -> p

    # ggsave(filename=paste("./17210641-dstat.png", sep=""),
    # plot = p, height=2.5, width=6)



    # mutate(t = timestamp - min(timestamp)) %>%
    # mutate(proc = component_id - min(component_id)) %>%
    # ggplot(aes(x=t, y=ioctl), color="blue") +
    # geom_point(linewidth=0.1) + 
    # my_theme() + theme(panel.grid.major.x=element_blank(), legend.position="top") +
    # scale_x_continuous("Timestamp", expand=c(0,0)) + 
    # scale_y_continuous("Component ID", lim=c(0, NA)) +
    # guides(color=guide_legend(title="I/O Wait")) +
    # scale_size(range = c(0.2, 5)) +
    # ggtitle("HACC-IO 10 million particles - I/O stressor") +
    # guides(fill=guide_legend(title="Length (Bytes)")) -> p

    # ggsave(filename=paste("./17209783-dstat.png", sep=""),
    # plot = p, height=2.5, width=6)