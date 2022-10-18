#!/bin/sh

function handler() {
    declare -a md5Arr
    declare -a sha1Arr
    declare -a nameArr
    declare -a dataArr
    declare -a hashArr

    # get json elements
    nameArr=($(cat ${inputFile} | sed -n '{s/ //g; s/"//g; s/,//g; /name/ p;}'))
    dataArr=($(cat ${inputFile} | sed -n '{s/ //g; s/"//g; s/,//g; /data/ p;}'))
    hashArr=($(cat ${inputFile} | sed -n '{s/ //g; s/"//g; s/hash:{//g; s/}//g; /md5/ p;}'))
    hashArr=($(awk -v var="${hashArr[*]}" 'BEGIN {split(var,list,","); for (i=1;i<=length(list);i++) print list[i]}'))
    for i in ${hashArr[*]}; do
        md5Arr+=($(echo $i | grep "md5"))
    done
    for i in ${hashArr[*]}; do
        sha1Arr+=($(echo $i | grep "sha-1"))
    done

    # run each file case
    declare -i count=0
    while [ ${count} -lt ${#nameArr[@]} ]; do
        if [ ${count} -ne 0 ]; then
            name=($(echo "${nameArr[${count}]}" | awk 'BEGIN {FS=":"} {print $2}'))
            data=($(echo "${dataArr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))
            md5=($(echo "${md5Arr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))
            sha1=($(echo "${sha1Arr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))

            echo ${data} | base64 --decode
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

        fi
        count=count+1
    done

}


inputFile=""
outputFile=""
outputDir=""
declare -i isC=0
declare -i isJ=0

OPTERR=0
while getopts i:o:c:j op; do
    case $op in
        i)
            inputFile=${OPTARG}
            ;;
        o)
            outputDir=${OPTARG} 
            ;;
        c)
            if [ ${OPTARG} = "csv" ]; then
                isC=1 #csv
            else
                isC=2 #tsv
            fi
            outputFile=${OPTARG}
            ;;
        j)
            # Output info.json
            isJ=1
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

# call function => decode the file
handler