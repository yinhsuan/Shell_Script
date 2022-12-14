#!/bin/sh

function handler() {
    declare -a md5Arr
    declare -a sha1Arr
    declare -a nameArr
    declare -a dataArr
    declare -a hashArr

    # get json elements
    authorArr=($(cat ${inputFile} | sed -n '{s/ //g; s/"//g; s/,//g; /author/ p;}'))
    dateArr=($(cat ${inputFile} | sed -n '{s/ //g; s/"//g; s/,//g; /date/ p;}'))
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

    
    # output info.json
    if [ ${isJ} -eq 1 ]; then
        name=($(echo "${nameArr[0]}" | awk 'BEGIN {FS=":"} {print $2}'))
        author=($(echo "${authorArr[0]}" | awk 'BEGIN {FS=":"} {print $2}'))
        date=($(echo "${dateArr[0]}" | awk 'BEGIN {FS=":"} {print $2}'))
        formatDate=($(date -I seconds -r ${date}))
        jsonpath=${outputDir}"/info.json"
        printf "{\"name\": \"%s\", \"author\": \"%s\", \"date\": \"%s\"}" "${name}" "${author}" "${formatDate}" > "${jsonpath}"
    fi

    # run each file case
    declare -i count=0
    while [ ${count} -lt ${#nameArr[@]} ]; do
        if [ ${count} -ne 0 ]; then
            dirandname=($(echo "${nameArr[${count}]}" | awk 'BEGIN {FS=":"} {print $2}'))
            # dir=($(echo "${dirandname}" | sed -n '{s/${name}//g;}'))
            # name=($(echo "${dirandname}" | awk -F "/" '{print $NF}'))
            dir="$(dirname "${dirandname}")"
            name="$(basename "${dirandname}")"
            data=($(echo "${dataArr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))
            md5=($(echo "${md5Arr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))
            sha1=($(echo "${sha1Arr[${count}-1]}" | awk 'BEGIN {FS=":"} {print $2}'))
            csvpath=${dir}"/files.csv"
            tsvpath=${dir}"/files.tsv"

            # create dir & files
            mkdir -p ${outputDir}"/"${dirandname%/*}

            # output files
            echo "${data}" | base64 --decode > ${outputDir}"/"${dirandname}

            # output csv or tsv
            size=$(($(wc -c < ${outputDir}"/"${dirandname}))) # get the size with blank in the front
            if [ ${isC} -eq 1 ]; then
                echo "${name},${size},${md5},${sha1}" > ${outputDir}"/"${csvpath}
            elif [ ${isC} -eq 2 ]; then
                printf "%s\t%s\t%s\t%s\n" "${name}" "${size}" "${md5}" "${sha1}" > ${outputDir}"/"${tsvpath}
            fi
        fi
        count=count+1
    done

}


inputFile=""
outputFile=""
outputDir=""
declare -i isC=0 #isC=1(csv) #isC=2(tsv)
declare -i isJ=0

OPTERR=0
while getopts i:o:c:j op; do
    case $op in
        i)
            inputFile=${OPTARG}
            ;;
        o)
            outputDir=${OPTARG} 
            mkdir -p "${outputDir}"
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

# call function
handler