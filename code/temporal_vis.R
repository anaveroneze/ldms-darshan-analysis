
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
