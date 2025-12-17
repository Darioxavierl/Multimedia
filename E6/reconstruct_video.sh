#!/bin/bash

# Script to reconstruct video using etmp4 from EvalVid
# Usage: ./reconstruct_video.sh <tx_dump> <rx_dump> <trace_file> <original_video> <output_video>

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate arguments
if [[ $# -ne 5 ]]; then
    echo -e "${RED}Error: Invalid number of arguments${NC}"
    echo "Usage: $0 <tx_dump> <rx_dump> <trace_file> <original_video> <output_video>"
    echo ""
    echo "Example:"
    echo "  $0 Tx/tx_dump Rx/rx_dump ./trazas/100k.f Tx/videos/100k/mobile_cif_100k.mp4 reconstructed_100k.mp4"
    exit 1
fi

TX_DUMP="$1"
RX_DUMP="$2"
TRACE_FILE="$3"
ORIGINAL_VIDEO="$4"
OUTPUT_VIDEO="$5"

# Verify input files exist
echo -e "${YELLOW}Validating input files...${NC}"

if [[ ! -f "$TX_DUMP" ]]; then
    echo -e "${RED}Error: TX dump file not found: $TX_DUMP${NC}"
    exit 1
fi

if [[ ! -f "$RX_DUMP" ]]; then
    echo -e "${RED}Error: RX dump file not found: $RX_DUMP${NC}"
    exit 1
fi

if [[ ! -f "$TRACE_FILE" ]]; then
    echo -e "${RED}Error: Trace file not found: $TRACE_FILE${NC}"
    exit 1
fi

if [[ ! -f "$ORIGINAL_VIDEO" ]]; then
    echo -e "${RED}Error: Original video file not found: $ORIGINAL_VIDEO${NC}"
    exit 1
fi

echo -e "${GREEN}All input files found ✓${NC}"

# Check if etmp4 is available
if ! command -v ~/evalvid/etmp4 &> /dev/null; then
    echo -e "${RED}Error: etmp4 not found at ~/evalvid/etmp4${NC}"
    exit 1
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_VIDEO")
if [[ -n "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
    mkdir -p "$OUTPUT_DIR"
fi

# Check if output file already exists
if [[ -f "$OUTPUT_VIDEO" ]]; then
    echo -e "${YELLOW}Warning: Output file already exists: $OUTPUT_VIDEO${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
fi

# Run etmp4 reconstruction
echo -e "${YELLOW}Starting video reconstruction...${NC}"
echo "Command: ~/evalvid/etmp4 -f -0 $RX_DUMP $TRACE_FILE $ORIGINAL_VIDEO $OUTPUT_VIDEO"
echo ""

cd Rx/videos_recontruidos || exit 1

if ~/evalvid/etmp4 -f -0 "$TX_DUMP" "$RX_DUMP" "$TRACE_FILE" "$ORIGINAL_VIDEO" "$OUTPUT_VIDEO"; then
    echo ""
    echo -e "${GREEN}Video reconstruction completed successfully! ✓${NC}"
    echo -e "${GREEN}Output file: $OUTPUT_VIDEO${NC}"
    
    # Verify output file was created
    if [[ -f "$OUTPUT_VIDEO" ]]; then
        OUTPUT_SIZE=$(ls -lh "$OUTPUT_VIDEO" | awk '{print $5}')
        echo -e "${GREEN}File size: $OUTPUT_SIZE${NC}"
    fi
else
    echo -e "${RED}Error: Video reconstruction failed${NC}"
    exit 1
fi
