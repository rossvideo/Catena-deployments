#!/bin/sh

if [ $CATENA_CONNECTION = "gRPC" ]; then
    grpc_health_probe -addr=:$CATENA_PORT || exit 1
elif [ $CATENA_CONNECTION = "REST" ]; then
    wget -q --spider http://localhost:$CATENA_PORT/st2138-api/v1/health || exit 1
else
    echo "Unknown connection type $CATENA_CONNECTION, exiting."
    exit 1
fi