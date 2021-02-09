#!/bin/bash

# User defined settings
NUM_WORKER=2
MASTER_HOST=crimac-master

DATAIN=/data/cruise_data/2020/S2020842_PHELMERHANSSEN_1173/ACOUSTIC/EK60/EK60_RAWDATA
DATAOUT=/localscratch/ibrahim-echo/out
OUTPUT_TYPE=zarr
MAIN_FREQ=38000
MAX_RANGE_SRC=auto
OUTPUT_NAME=parallel-test
WRITE_PNG=0

# Placeholder for ids
ids=()

# Start the scheduler
ret=$(docker run -dit --name $MASTER_HOST \
  --env MODE=master \
  -p 8786:8786 \
  -v $DATAIN:/datain \
  -v $DATAOUT:/dataout \
  crimac/preprocessor:parallel)
ids+=($ret)

# Loop to start the workers
for (( i = 0; i <= $NUM_WORKER; i++ ))
do
  ret=$(docker run -dit --link $MASTER_HOST \
    --env MODE=worker \
    --env MASTER_HOST=$MASTER_HOST \
    -v $DATAIN:/datain \
    -v $DATAOUT:/dataout \
    crimac/preprocessor:parallel)
  ids+=($ret)
done

# Start the preprocessing script
docker run -it --name run --link $MASTER_HOST \
  -v $DATAIN:/datain \
  -v $DATAOUT:/dataout \
  --security-opt label=disable \
  --env MASTER_HOST=$MASTER_HOST \
  --env OUTPUT_TYPE=$OUTPUT_TYPE \
  --env MAIN_FREQ=$MAIN_FREQ \
  --env MAX_RANGE_SRC=$MAX_RANGE_SRC \
  --env OUTPUT_NAME=$OUTPUT_NAME \
  --env WRITE_PNG=$WRITE_PNG \
  crimac/preprocessor:parallel

# Cleaning up
for id in "${ids[@]}"
do
     docker kill $id && docker rm $id
done

docker rm $(docker ps -aqf "name=run")
