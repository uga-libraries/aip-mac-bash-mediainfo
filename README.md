# Making an AIP on Mac/Linux with Bash Script and MediaInfo

# Purpose:

Transform a batch of folders into Archival Information Packages (AIPS), including generating PREMIS metadata, using two bash scripts, free tools, and xslt stylesheets on a Mac or Linux operating system.

# Description:

This script performs the following tasks:

    1.  Validates bags if contents were previously bagged.
    2.  Organizes the AIP folders into objects and metadata subfolders.
    3.  Runs MediaInfo to extract technical metadata.
    4.  Creates PREMIS XML file (called master.xml)
    5.  Validates the PREMIS XML.
    6.  Organizes the MediaInfo and PREMIS files. 
    7.  Bags the AIPs.
    8.  Validates the bags.
    9.  Tars and zips the AIPs.
    10. Generates a MD5 manifest of the zipped AIPs.

A diagram of the AIP workflow is included in PDF form in the documentation folder. 

# Usage:

The contents of each aip should be in an individual folder, named with the convention aip-id_some-title. 

This script can be used on both bagged and non-bagged folders. If a bag, the script will first break apart the bag structure before starting to transform its contents.

The script executes many of the commands based on the assumption that folders follow the naming convention for our library unit (i.e. starting with the letter combitionation 'rbrl'.) The more you can standardize your filenames and foldernames before running the script, the fewer errors you are likely to encounter when running this on batches of folders. 

To run the script:
In the command line, put the absolute filepath of the aip-creation.sh script. Then put the absolute filepath of your source directory (i.e. directory containing AIP folders). 

If you do not put both of the required filepaths from above, an error message will prompt you do so. The script will not run unless it has both arguments. 

# Dependencies:

    -   bagit.py (https://github.com/LibraryOfCongress/bagit-python)
    -   MediaInfo (https://mediaarea.net/en/MediaInfo/Download)
    -   md5deep (https://github.com/jessek/hashdeep/releases)
    -   saxon9he xslt processor (http://saxon.sourceforge.net/)
    -   xmlint (command line utility that should come installed on a Mac/Linux machine)

# Installation:

    1.  Install the dependencies (listed above).
    2.  Download the "aip-workflowdocs" folder with the scripts, stylesheets, and other files needed for the workflow from GitHub and save to your computer.
    3.  Update the filepath variables in the aip-creation.sh script (lines 31-32) to the location of the aip-workflowdocs folder and Saxon program on your computer.
    4.  Update the base-uri in the stylesheets and DTD to the base for your identifiers:
            i.  mediainfo-to-master.xsl: in variable name="uri" (line 42)
            ii. premis.xsd: in the restriction pattern for objectIdentifierType (line 35)
    5.  Change permission on the script so that it is executable.

# Acknowledgements:

This workflow was modeled off the aip-mac-bash-fits workflow developed by Adriane Hanson, Head of Digital Stewardship at University of Georgia Libraries. 

The aip-creation script incorporates a perl script to tar and zip files that was developed by Shawn Kiewel, UGA Libraries Application Analyst.


