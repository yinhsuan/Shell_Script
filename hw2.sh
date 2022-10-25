#!/bin/sh

handler() {
    # get variable
    name=`cat ${inputFile} | jq '.name' | sed '{s/"//g;}'`
    author=`cat ${inputFile} | jq '.author' | sed '{s/"//g;}'`
    date=`cat ${inputFile} | jq '.date' | sed '{s/"//g;}'`

    # output info.json
    if [ ${isJ} -eq 1 ]; then
        formatDate=`date -I seconds -r ${date}`
        jsonpath=${outputDir}"/info.json"
        printf "{\"name\": \"%s\", \"author\": \"%s\", \"date\": \"%s\"}" "${name}" "${author}" "${formatDate}" > "${jsonpath}"
    fi

    # run each file case
    counter=0;
    jq -rc '.files[]' ${inputFile} | while IFS=, read var1 var2 var3; do echo "$var1, $var2, $var3" > ${counter}.json; counter=$(($counter+1)); done

    for jsonFile in `ls *json`; do
        dirandname=`cat ${jsonFile} | jq '.name' | sed '{s/"//g;}'`
        data=`cat ${jsonFile} | jq '.data' | sed '{s/"//g;}'`
        md5=`cat ${jsonFile} | jq '.hash.md5' | sed '{s/"//g;}'`
        sha1=`cat ${jsonFile} | jq '.hash."sha-1"' | sed '{s/"//g;}'`

        dir="$(dirname "${dirandname}")"
        name="$(basename "${dirandname}")"
        csvpath=${dir}"/files.csv"
        tsvpath=${dir}"/files.tsv"

        # create dir & files
        mkdir -p ${outputDir}"/"${dirandname%/*}

        # output files
        echo "${data}" | base64 --decode > ${outputDir}"/"${dirandname}

        # output csv or tsv
        size=`ls -l ${outputDir}"/"${dirandname} | awk 'BEGIN {FS=" "} {print $5}'`

        if [ ${isC} -eq 1 ]; then
            echo "${name},${size},${md5},${sha1}" > ${outputDir}"/"${csvpath}
        elif [ ${isC} -eq 2 ]; then
            printf "%s\t%s\t%s\t%s\n" "${name}" "${size}" "${md5}" "${sha1}" > ${outputDir}"/"${tsvpath}
        fi
    done

}


inputFile=""
outputFile=""
outputDir=""
isC=0 #isC=1(csv) #isC=2(tsv)
isJ=0

errorMsg() {
    echo "hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]"
    echo ""
    echo "Available Options:"
    echo ""
    echo "-i: Input file to be decoded"
    echo "-o: Output directory"
    echo "-c csv|tsv: Output files.[ct]sv"
    echo "-j: Output info.json"
    exit 1
} >&2

while getopts :i:o:c:j op; do
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
            errorMsg
            ;;
        esac
done

# call function
handler