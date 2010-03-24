#!/bin/sh

# This script requires Apache Batik 
BATIK_DIR="${HOME}/batik-1.7"
RASTERIZER="java -jar ${BATIK_DIR}/batik-rasterizer.jar"

${RASTERIZER} -m image/png -w 29 -h 29 -d ../Icon-Small.png OATH_Token.svg
${RASTERIZER} -m image/png -w 57 -h 57 -d OATH_Token57.png OATH_Token.svg
${RASTERIZER} -m image/jpeg -q 0.95 -w 512 -h 512 -d OATH_Token512.jpg OATH_Token.svg

