#!/bin/bash


    saxon='/home/digipres/aip-apps/saxon'
    workflowdocs='/home/digipres/aip-russell-ohm/workflowdocs'

# Checks that got the required input (path of source directory)
    if [ -z "$1" ];
        then echo "Error - need to include the source directory"
        exit 1
    fi

# Checks that the source directory path is valid
    if [ ! -d "$1" ]; then
        echo "Source directory does not exist."
        exit 1
    fi

# Changes to source directory
cd $1

echo ""
echo ""

# Deletes all .DS_Store files in the source directory and subdirectories as a cleanup measure before bagging
# -iname allows for case-insensitive matching
    find . -iname ".DS_Store" -type f -delete


# First tests whether directory beginning with 'rbrl' exists.
# Then examines the master.xml file, testing whether it contains 'media' or 'metadata' in its name to know how to rename the directory
# Bags the proto-aips (MD5 and SHA-256 manifests) and in the process renames to aip-id_media_bag OR aip-id_metadata_bag
# Removes --quiet if you want to see the details on the tool's progress

    for d in rbrl*; do
        if [ -d "$d" ]; then
            for i in $d/metadata; do

                if [ -f $i/*media_master.xml ]; then
                    bagit.py --md5 --sha256 --quiet "$d"
                    mv $d ${d}_media_bag

                elif [ -f $i/*metadata_master.xml ]; then
                    bagit.py --md5 --sha256 --quiet "$d"
                    mv $d ${d}_metadata_bag
                fi
            done
        fi
    done

# Validates the bags
# Separates step from previous because combining for loop caused an error

    for d in rbrl*; do
        if [ -d "$d" ]; then
          bagit.py --validate "$d"
        fi
    done


if [ ! -d aips-to-ingest ]; then mkdir aips-to-ingest; fi


# Runs prepare_bag script on all bagged aips and saves in the aips-to-ingest directory
# note: prepare_bag script renames file to include the uncompressed file size in bytes
    for d in rbrl*; do
        if [[ -d "$d" && -f aips-to-ingest/* ]]; then
            perl "$workflowdocs"/prepare_bag $d aips-to-ingest
        fi
    done

# Generates checksum manifest on files in aips-to-ingest folder

    # first changes directories
    cd aips-to-ingest

    # then sets a current_date variable
    current_date=`date +"%Y%m%d"`

    # finally, after checking that directory is not empty, generates manifest
    # manifest is named with the current date, so that running the script on the same directory does not overwrite a previous manifest
    if [ -f * ]; then
        md5deep -b * > ${current_date}_manifest.txt
    else
        echo "Did not generate MD5 manifest: no AIPs in directory"
    fi

echo ""
echo "Script is complete!"
echo ""

