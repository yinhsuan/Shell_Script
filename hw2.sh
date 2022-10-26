#!/bin/sh

handler() {
    # get variable
    name=`cat ${inputFile} | jq '.name' | sed '{s/"//g;}'`
    author=`cat ${inputFile} | jq '.author' | sed '{s/"//g;}'`
    date=`cat ${inputFile} | jq '.date' | sed '{s/"//g;}'`

    csvpath=${outputDir}"/files.csv"
    tsvpath=${outputDir}"/files.tsv"

    # output info.json
    if [ ${isJ} -eq 1 ]; then
        formatDate=`date -Iseconds -r ${date}`
        jsonpath=${outputDir}"/info.json"
        printf "{\"name\": \"%s\", \"author\": \"%s\", \"date\": \"%s\"}" "${name}" "${author}" "${formatDate}" > "${jsonpath}"
    fi

    # output csv & tsv
    if [ ${isC} -eq 1 ]; then
        echo "filename,size,md5,sha1" > ${csvpath}
    elif [ ${isC} -eq 2 ]; then
        echo -e "filename\tsize\tmd5\tsha1" > ${tsvpath}
    fi

    # run each file case
    counter=0
    jq -rc '.files[]' ${inputFile} | while IFS=, read var1 var2 var3; do echo "$var1, $var2, $var3" > ${counter}.json; counter=$(($counter+1)); done

    invalidFileCount=0
    for jsonFile in `ls *json`; do
        dirandname=`cat ${jsonFile} | jq '.name' | sed '{s/"//g;}'`
        data=`cat ${jsonFile} | jq '.data' | sed '{s/"//g;}'`
        echo "${data}" > "data.txt"
        md5=`cat ${jsonFile} | jq '.hash.md5' | sed '{s/"//g;}'`
        sha1=`cat ${jsonFile} | jq '.hash."sha-1"' | sed '{s/"//g;}'`

        dir="$(dirname "${dirandname}")"
        name="$(basename "${dirandname}")"

        # checksum
        md5Check=`md5sum data.txt | awk 'BEGIN {FS=" "} {print $1}'`
        sha1Check=`sha1sum data.txt | awk 'BEGIN {FS=" "} {print $1}'`
        if ![ ${md5} == ${md5Check} -a ${sha1} == ${sha1Check} ]; then
            md5=${md5Check}
            sha1=${sha1Check}
            invalidFileCount=$(($invalidFileCount+1))
        fi
        
        # create dir & files
        mkdir -p ${outputDir}"/"${dir}

        # output files
        echo "${data}" | base64 --decode > ${outputDir}"/"${dirandname}

        # output to csv or tsv
        size=`ls -l ${outputDir}"/"${dirandname} | awk 'BEGIN {FS=" "} {print $5}'`
        if [ ${isC} -eq 1 ]; then
            echo "${dirandname},${size},${md5},${sha1}" >> ${csvpath}
        elif [ ${isC} -eq 2 ]; then
            printf "%s\t%s\t%s\t%s\n" "${dirandname}" "${size}" "${md5}" "${sha1}" >> ${tsvpath}
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
exit ${invalidFileCount}