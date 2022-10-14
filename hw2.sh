#!/bin/sh
OPTERR=0
while getopts i:o:c:j op; do
    case $op in
        i)
            echo "i: "${OPTARG}
            ;;
        o)
            echo "o: "${OPTARG} 
            ;;
        c)
            echo "c: "${OPTARG}
            ;;
        j)
            # Output info.json
            ;;
        *)
            {
                echo "hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]\n"
                echo "Available Options:\n"
                echo "-i: Input file to be decoded"
                echo "-o: Output directory"
                echo "-c csv|tsv: Output files.[ct]sv"
                echo "-j: Output info.json"
            } >&2
            exit 1
            ;;
        esac
done