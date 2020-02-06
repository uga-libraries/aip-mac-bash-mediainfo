#!/bin/bash

# To run: put the path to the script and the path of the source directory into the terminal

########

# Filepath variables: give the absolute filepath for MediaInfo, Saxon, and workflowdocs folder (where scripts, stylesheets, DTDs, etc. are saved)
# Update these here and they will be updated wherever they appear in the rest of the script

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

# Runs prepare_bag script on all bagged aips and saves in the aips-to-ingest directory
# note: prepare_bag script renames file to include the uncompressed file size in bytes
    for d in rbrl*; do
        if [ -d "$d" ]; then
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
