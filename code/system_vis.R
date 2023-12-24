
source("./analysis/initialization.R")

plot_temporal <- function(filename, filename_sys, figname) { 

    df <- read_csv(filename) %>%
        mutate(start = timestamp - dur) %>%
        mutate(end_datetime = as_datetime(timestamp),
            start_datetime = as_datetime(start),) %>%
        mutate(start_zero = start - min(start)) %>%
        mutate(end_zero = start_zero + dur) %>%
        filter(module == "POSIX") 

    df.system <- read_csv(filename_sys) %>%
        filter(timestamp >= min(df$start)) %>%
        filter(timestamp <= max(df$timestamp))
    
    df %>% print()
    df.system %>% print()

    df %>%
        ggplot(aes(xmin=start_datetime, xmax=end_datetime, ymin=rank-0.4, ymax=rank+0.4, fill=op)) +
        geom_rect() + theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        my_theme() + 
        theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        scale_x_datetime(date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        scale_y_continuous("Rank ID", expand=c(0,0), lim=c(-0.5, NA), breaks=seq(0,124,4)) +
        guides(fill=guide_legend(title="Operation")) -> p1     

    df.system %>%
        mutate(t_datetime = as_datetime(timestamp)) %>%
        ggplot(aes(x=t_datetime, y=procs_running)) +
        geom_line() + geom_point() + my_theme() + 
        theme(panel.grid.major.x=element_blank(),  axis.title.x=element_blank()) +  
        scale_x_datetime(date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        guides(fill=guide_legend(title="Operation")) -> p2 

    df.system %>%
        mutate(t_datetime = as_datetime(timestamp)) %>%
        ggplot(aes(x=t_datetime, y=procs_blocked)) +
        geom_line() + geom_point() + my_theme() + 
        theme(panel.grid.major.x=element_blank(),  axis.title.x=element_blank()) +  
        scale_x_datetime(date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        guides(fill=guide_legend(title="Operation")) -> p3

    df.system %>%
        mutate(t_datetime = as_datetime(timestamp)) %>%
        ggplot(aes(x=t_datetime, y=iowait)) +
        geom_line() + geom_point() + my_theme() + 
        theme(panel.grid.major.x=element_blank(), axis.title.x=element_blank()) + 
        scale_x_datetime(date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        guides(fill=guide_legend(title="Operation")) -> p4

    df.system %>%
        mutate(t_datetime = as_datetime(timestamp)) %>%
        ggplot(aes(x=t_datetime, y=user+sys)) +
        geom_line() + geom_point() + my_theme() + 
        theme(panel.grid.major.x=element_blank()) + 
        scale_x_datetime("Execution time", date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        guides(fill=guide_legend(title="Operation")) -> p5

    df.system %>%
        mutate(t_datetime = as_datetime(timestamp)) %>%
        ggplot(aes(x=t_datetime, y=softirq)) +
        geom_line() + geom_point() + my_theme() + 
        theme(panel.grid.major.x=element_blank()) + 
        scale_x_datetime("Execution time", date_breaks = "10 min", expand=c(0,0), date_labels = "%H:%M:%S") +
        guides(fill=guide_legend(title="Operation")) -> p6

    ggsave(filename=figname, plot = p1/p2/p3/p4/p5/p6, height=8, width=10)                                                                
}