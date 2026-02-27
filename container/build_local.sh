set -e

TEMP_DIR=$(mktemp -d)
CONNECTION=gRPC
GRAB_EXAMPLE=${1:-"$CONNECTION/examples/one_of_everything/one_of_everything"}
EXAMPLE_NAME=$(basename $GRAB_EXAMPLE)
EXAMPLE_PATH=$TEMP_DIR/examples/$EXAMPLE_NAME

mkdir -p $EXAMPLE_PATH

docker run --rm -v $EXAMPLE_PATH:/cache -v catena-build:/source alpine:latest cp -r /source/connections/$GRAB_EXAMPLE /cache/
cp -r ~/Catena/sdks/cpp/connections/$(dirname $GRAB_EXAMPLE)/static $EXAMPLE_PATH

mkdir -p $TEMP_DIR/container
cp healthcheck.sh $TEMP_DIR/container

if which tree > /dev/null; then
    tree $TEMP_DIR
else
    find $TEMP_DIR
fi

docker build -t catena-container:local -f Dockerfile $TEMP_DIR --build-arg CONNECTION=$CONNECTION --build-arg EXAMPLE=$EXAMPLE_NAME \
    --build-arg EXAMPLE_PATH=${EXAMPLE_PATH#"$TEMP_DIR/"} --build-arg WORKDIR=~/Catena --target=$CONNECTION
