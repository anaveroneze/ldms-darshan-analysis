
source("./analysis/initialization.R")

plot_temporal <- function(filename, figname) { 

    df <- read_csv(filename) %>%
        mutate(start = timestamp - dur) %>%
        mutate(end_datetime = as_datetime(timestamp),
            start_datetime = as_datetime(start),) %>%
        mutate(start_zero = start - min(start)) %>%
        mutate(end_zero = start_zero + dur) %>%
        filter(module == "POSIX")               

    df %>%
        ggplot(aes(xmin=start_datetime, xmax=end_datetime, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
        geom_rect() + theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        ggtitle("Temporal visualization of I/O operations") +
        my_theme() + scale_x_datetime("Execution time", date_breaks = "10 sec", expand=c(0,0), date_labels = "%H:%M:%S") +
        scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,4)) +
        guides(fill=guide_legend(title="Operation")) -> p      

    ggsave(filename=figname, plot = p, height=3, width=10)                                                                   
}

plot_long_temporal <- function(filename, figname) { 

    df <- read_csv(filename) %>%
        mutate(start = timestamp - dur) %>%
        mutate(end_datetime = as_datetime(timestamp),
            start_datetime = as_datetime(start),) %>%
        mutate(start_zero = start - min(start)) %>%
        mutate(end_zero = start_zero + dur) %>%
        filter(module == "POSIX")               

    # Filter only operations that took longer than the median
    df %>% group_by(op) %>% 
        mutate(median_dur = median(dur)) %>%
        ungroup() %>%
        filter(dur > median_dur) %>%
        ggplot(aes(xmin=start_datetime, xmax=end_datetime, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
        geom_rect() + theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        ggtitle("I/O operations with duration longer than the median duration per operation") +
        my_theme() + scale_x_datetime("Execution time", date_breaks = "10 sec", expand=c(0,0), date_labels = "%H:%M:%S") +
        scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,4)) +
        guides(fill=guide_legend(title="Operation")) -> p      

    ggsave(filename=figname, plot = p, height=3, width=10)                                                                   
}

plot_max_temporal <- function(filename, figname) { 

    df <- read_csv(filename) %>%
        mutate(start = timestamp - dur) %>%
        mutate(end_datetime = as_datetime(timestamp),
            start_datetime = as_datetime(start),) %>%
        mutate(start_zero = start - min(start)) %>%
        mutate(end_zero = start_zero + dur) %>%
        filter(module == "POSIX")               

    # Filter only operations that took longer than the median
    df %>% group_by(op, rank) %>% 
        mutate(max_dur = max(dur)) %>%
        filter(dur == max_dur) %>%
        ungroup() %>%
        ggplot(aes(xmin=start_datetime, xmax=end_datetime, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
        geom_rect() + theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        ggtitle("I/O operations with longer duration for each rank") +
        my_theme() + scale_x_datetime("Execution time", date_breaks = "10 sec", expand=c(0,0), date_labels = "%H:%M:%S") +
        scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,4)) +
        guides(fill=guide_legend(title="Operation")) -> p      

    ggsave(filename=figname, plot = p, height=3, width=10)                                                                   
}

plot_duration <- function(filename, figname) { 

    df <- read_csv(filename) %>% 
        filter(op %in% c("write", "read")) %>% 
        group_by(rank, op) %>% 
        summarise(mean_dur = mean(dur), median_dur = median(dur), sum_dur = sum(dur)) -> df.plot 

    df.plot %>%
        ggplot(aes(x = rank, y=mean_dur, fill=op)) +
        geom_bar(stat="identity", position = "dodge", color="black") + 
        my_theme() +
        scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,1)) +
        scale_y_continuous("Mean duration\n(seconds)", expand=c(0,0), lim=c(0, NA)) +
        guides(fill=guide_legend(title="Operation")) -> p1      

    df.plot %>%
        ggplot(aes(x = rank, y=median_dur, fill=op)) +
        geom_bar(stat="identity", position = "dodge", color="black") + 
        my_theme() +
        scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,1)) +
        scale_y_continuous("Median duration\n(seconds)", expand=c(0,0), lim=c(0, NA)) +
        guides(fill=guide_legend(title="Operation")) + theme(legend.position="none") -> p2

    df.plot %>%
        ggplot(aes(x = rank, y=sum_dur, fill=op)) +
        geom_bar(stat="identity", position = "dodge", color="black") + 
        my_theme() +
        scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,1)) +
        scale_y_continuous("Sum duration\n(seconds)", expand=c(0,0), lim=c(0, NA), breaks=seq(0,10000,10)) +
        guides(fill=guide_legend(title="Operation")) + theme(legend.position="none") -> p3

    ggsave(filename=figname, plot = p1/p2/p3, height=6, width=10)                                                                   
}

plot_bandwidth_per_rank <- function(filename, figname) { 

    df <- read_csv(filename) %>%
        filter(op == "write") %>% 
        group_by(op, rank) %>% 
        summarise(bw = sum(len)/(2^20)/sum(dur)) %>%
        ggplot(aes(rank, op, fill= bw)) + 
        geom_tile() + scale_fill_viridis(discrete=FALSE, name="Bandwidth (MiB/seconds)") +
        scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,2)) +
        my_theme() + theme(axis.title.y = element_blank()) -> p1    

    df <- read_csv(filename) %>%
        filter(op == "read") %>% 
        group_by(op, rank) %>% 
        summarise(bw = sum(len)/(2^20)/sum(dur)) %>%
        ggplot(aes(rank, op, fill= bw)) + 
        geom_tile() + scale_fill_viridis(discrete=FALSE, name="Bandwidth (MiB/seconds)") +
        scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,2)) +
        my_theme() + theme(axis.title.y = element_blank()) -> p2

    ggsave(filename=figname, plot = p1/p2, height=3.5, width=8)                                                                   
}


plot_heatmap_temporal <- function(filename, figname) { 

    df <- read_csv(filename) %>%
        mutate(start = timestamp - dur) %>%
        mutate(end_datetime = as_datetime(timestamp),
            start_datetime = as_datetime(start),) %>%
        mutate(start_zero = start - min(start)) %>%
        mutate(end_zero = start_zero + dur) %>%
        filter(module == "POSIX")               

    df %>%
        filter(op == "read") %>% 
        mutate(TIME_SLICE = round_time(start_datetime, unit = "0.5 seconds")) %>%
        group_by(TIME_SLICE, rank) %>%
        summarise(n=n(), bw = (sum(len)/(2^20))/sum(dur)) %>% print()

    # df.slices %>%
    #     ggplot(aes(rank, TIME_SLICE, fill= bw)) + 
    #     geom_tile() + scale_fill_viridis(discrete=FALSE, name="Bandwidth (MiB/seconds)") +
    #     scale_x_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,2)) +
    #     my_theme() + theme(axis.title.y = element_blank()) -> p

    # ggsave(filename=figname, plot = p, height=3, width=10)                                                               
}