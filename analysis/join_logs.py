import pandas as pd
import glob
from natsort import natsorted 
from fastparquet import write

col_names = ['rank', 'file', 'record_id', 'module', 'type', 'max_byte', 
    'switches', 'flushes', 'cnt', 'op', 'pt_sel', 'irreg_hslab', 'reg_hslab', 'ndims', 
    'npoints', 'off', 'len', 'start', 'dur', 'total', 'timestamp']
folder_path = './ior/eclipse/darshan-ldms/csv/'
file_pattern = '*.csv'

# Get a list of file paths that match the pattern
file_paths = natsorted(glob.glob(folder_path + file_pattern))
print(file_paths)

all_df = pd.DataFrame()
# Loop through the file paths and read each CSV file into a DataFrame
for file_path in file_paths:
    print(file_path)
    df = pd.read_csv(file_path, usecols=col_names)
    all_df = pd.concat([all_df, df], ignore_index=True)

write("./ior/eclipse/darshan-ldms/all.parquet", all_df)
