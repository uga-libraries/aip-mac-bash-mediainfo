# !/bin/bash

# Purpose: to restructure, process, and prep AIP directories for ingest into ARCHive digital preservation system
    # Normalizes file and folder names to lowercase
    # Deletes invisilbe/temporary files
    # Renames aip directories to match locally-defined aip-id
    # Creates 'objects' and 'metadata' folder in each aip directory
    # Generates mediainfo XML for each aip directory
    # Runs stylesheet transformation on mediainfo xml to generate PREMIS preservation metadata XML (called master.xml)
    # Validates master.xml and proceeds with script on AIPs with valid master.xml
    # Bags each AIP, validates bag
    # Tars and zips each AIP
    # Rsyncs tar/zip AIPs to ingest server
    # Genereates MD5 manifest for all tar/zip AIPs

# Requires Mediainfo, bagit.py, saxon xslt processor, prepare_bag script, master.xml dtds, and mediainfo stylesheets
# Script has one required arguments: the path of the directory contain the AIP folders (source directory)

# Prior to running the script:
    # Add optional metadata files to metadata subfolder in each AIP
    # Rename files according to chosen naming conventions
    # If this is the first time using these scripts on this computer, update the filepath variables

# To run: put the path to the script and the path of the source directory into the terminal

########

# Filepath variables: give the absolute filepath for MediaInfo, Saxon, and workflowdocs folder (where scripts, stylesheets, DTDs, etc. are saved)
# Update these here and they will be updated wherever they appear in the rest of the script

    saxon='insert-filepath'
    workflowdocs='insert-filepath'

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

# Recursively normalizes directories and filenames [ARCHive requires lowercase characters]
# first, makes all foldernames lowercase
    for f in `find . -depth ! -name CVS -type d`; do
        g=`dirname "$f"`/`basename "$f" | tr '[A-Z]' '[a-z]'`
        if [ "xxx$f" = "xxx$g" ]; then
            :
        else
            mv -f "$f" "$g"
        fi
    done

# Then, makes all filenames lowercase
    for f in `find . ! -type d`; do
        g=`dirname "$f"`/`basename "$f" | tr '[A-Z]' '[a-z]'`
        if [ "xxx$f" = "xxx$g" ]; then
            :
        else
            mv -f "$f" "$g"
        fi
    done

# if contents were bagged, removes all .txt files from each bag
    for d in rbrl*; do
         find . -type f -name *txt -delete
    done

# finds Audtion peak files (.pkf extension) and deletes them from a subfolder of avchd parent folder
    find . -iname "*.pkf" -type f -delete

# delete invisible .DS_Store files before beginning to restructure the folders
# -iname option allows for case-insensitive matching
    find . -iname '.DS_Store' -type f -delete

# rename the aip directories to match aip-id (e.g. rbrl###abc-###)
echo "renaming aip directories"

    for d in rbrl*; do
        if [ -d "$d" ]; then
            if [ $d = *_bag ]; then

                # first removes "_bag" ending and first instance of name in folder (e.g. _smith_bag)
                mv $d ${d%_*_bag}
            else
                # removes first instance of name
                    mv $d ${d%_*_*}
                # removes second instance of a name in the filename if there are two participant names (e.g. _firstname_lastname_bag)
                    mv $d ${d%_*}
            fi
        fi
    done


echo "restructuring aip directories"

    for d in rbrl* ; do
        if [ -d "$d"/data ]; then

            # for folders that were bagged, renames the 'data' folder to 'objects' folder in each aip-directory
                mv $d/data $d/objects

            # makes a new 'metadata' folder in each aip-directory if doesn't exist already
            if [ ! -d $d/metadata ]; then mkdir $d/metadata; fi

        else
            # makes a new 'objects' folder in each aip-directory
                if [ ! -d $d/objects ]; then mkdir $d/objects; fi
            # moves all files into 'objects' folder
                for files in `find $d/. -type f -maxdepth 1`; do
                    mv $files $d/objects/
                done
            # if avchd folder exists, moves it into 'objects' folder
                for folders in `find $d/. -type d -maxdepth 1 -name *avchd`; do
                    mv $folders $d/objects/
                done
            # makes a new 'metadata' folder in each aip-directory if doesn't exist already
                if [ ! -d $d/metadata ]; then mkdir $d/metadata; fi
        fi
    done

# GLOBIGNORE variable lists all the file extensions that will be ignored in script until the variable is unset

    GLOBIGNORE=*.mov:*.wav:*mp3*:*.dv:*avchd:*transcript.pdf:*ohms.xml:*dg.pdf:*notes.pdf:*transcript.doc:*transcript.docx

# since globignore variable is active, deletes all files from 'objects' folder EXCEPT the specified preservation files
	for d in rbrl*; do
		rm -v $d/objects/*
	done

	unset GLOBIGNORE #unsets the variable before moving on with the script


	# activate extended pattern matching
		shopt -s extglob

    if [ ! -d mediainfo-xml ]; then mkdir mediainfo-xml; fi

        # generates one mediainfo.xml file for files in each 'objects' folder of aip-directory
        # output is saved in the metadata folder of the aip
        # note about command options:
            # 'Output=OLDXML' maintains XML structure of MediaInfo versions before 18.03
            #  new MediaInfo versions output XML structure that do not correspond to our stylesheets
            # 'Language=raw' formats size to appear in bytes instead of KiB, MiB, or GiB (bytes are required for ARCHive metadata)

    for d in rbrl*; do
        if [ ! -f $d/metadata/*mediainfo.xml ]; then
            mediainfo -f --Output=OLDXML --Language=raw $d/objects > $d/metadata/${d}_mediainfo.xml
        fi


# uses grep to search for name matches in each mediainfo.xml
# if match found, will rename the mediainfo.xml with either _media or _metadata
    for i in rbrl*/metadata/*mediainfo.xml; do
        if grep -qE '(transcript|ohms|dg)' $i ; then
            mv $i ${i%mediainfo.xml}metadata_mediainfo.xml

        elif grep -qE '(mov|wav|dv|mp3)' $i ; then
            mv $i ${i%mediainfo.xml}media_mediainfo.xml

        else echo "MediaInfo XML was not generated for $i"
        fi
    done

# checks for existence, then copies each mediainfo.xml into 'mediainfo-xml' folder in source directory
    for d in rbrl*; do
        if [ -f $d/metadata/*mediainfo.xml ]; then
            cp "$d"/metadata/*mediainfo.xml mediainfo-xml/
        fi
    done


echo ""
echo "Mediainfo files copied to mediainfo-xml"
echo ""


if [ ! -d master-xml ]; then
    mkdir master-xml
fi

# runs two stylesheets to transform each mediainfo.xml into the master.xml in each aip directory

for d in rbrl*; do

    # 1. First runs the mediainfo-cleanup.xsl to restructure the media_mediainfo.xml so that the preservation master media file will always appear first in the output list
    # Saves the output as mediainfo-cleanup.xml in the metadata folder of each aip directory
        for i in $d/metadata/*mediainfo.xml; do
            if [ -f "$i" ]; then
                java -cp "$saxon"/saxon9he.jar net.sf.saxon.Transform -s:"$i" -xsl:"$workflowdocs"/mediainfo-cleanup.xsl -o:${i%_mediainfo.xml}_mediainfo-cleanup.xml
            else
                echo "${d} : error in generating mediainfo_cleanup.xml"
            fi
        done

    # 2. Then runs the mediainfo-to-master.xsl on the mediainfo-cleanup.xml
    # Saves the output in the metadata folder of each aip directory
        for i in $d/metadata/*mediainfo-cleanup.xml; do
            if [ -f "$i" ]; then
                java -cp "$saxon"/saxon9he.jar net.sf.saxon.Transform -s:"$i" -xsl:"$workflowdocs"/mediainfo-to-master.xsl -o:${i%_mediainfo-cleanup.xml}_master.xml
                # Then deletes the mediainfo-cleanup.xml file
                rm "$i"
            else
                echo "${d}: error in generating master.xml"
            fi
        done
done

echo ""
echo ""

# Validates master.xml file. If not valid, moves the proto-aip folder to a new folder in the source directory called master-invalid.
# The rest of the script does not run on aip directories with invalid master.xml files, saving the time of bagging, tarring, and zipping.

echo ""
echo "Validating master.xml files"
echo ""

if [ ! -d master-invalid ]; then
    mkdir master-invalid
fi

    for d in rbrl*; do
        # 2>&1 means the variable stores the value of xmllint's error output and the text it would have displayed in the terminal
        valid=$(( xmllint --noout -schema "$workflowdocs"/master.xsd "$d"/metadata/*_master.xml ) 2>&1)

        if [ -d "$d" ] && [ -f $d/metadata/*master.xml ]; then
            # One of these strings will be included in the tool output if there is a problem that staff need to investigate
                if [[ "$valid" == *"failed to load"* ]] || [[ "$valid" == *"fails to validate" ]]; then
                    mv "$d" master-invalid
                    echo "$d : invalid master.xml"
                elif cp "$d"/metadata/*_master.xml master-xml/; then
                    echo "master.xml files copied"
                else
                    echo "$d : master.xml does not exist"
                fi
            else
                mv "$d" master-invalid

        fi
    done

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
