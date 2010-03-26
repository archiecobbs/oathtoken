#!/bin/sh

# This script requires Apache Batik 
BATIK_DIR="${HOME}/batik-1.7"
RASTERIZER="java -jar ${BATIK_DIR}/batik-rasterizer.jar"

for SIZE in 29 57; do
    ${RASTERIZER} -m image/png -w ${SIZE} -h ${SIZE} -d OATH_Token${SIZE}.png OATH_Token.svg
done

${RASTERIZER} -m image/jpeg -q 0.95 -w 512 -h 512 -d OATH_Token512.jpg OATH_Token.svg

