# BIDS-MATLAB-tools

This repository contains a collection of functions to import and export BIDS-formated experiments. The code is tailored for use as an [EEGLAB](http://eeglab.org) plugin but may also be used independently of EEGLAB. Conversion of data format from non-supported BIDS binary format requires that EEGLAB be installed (supported formats are EEGLAB .set files, EDF files, BDF files, and Brain Vision Exchange Format files).

# BIDS-MATLAB vs EEG2BIDS vs BIDS-MATLAB-tools

[BIDS-MATLAB](https://bids-matlab.readthedocs.io/en/latest/) is a project to import BIDS data. BIDS-MATLAB maps the BIDS directory architectures to MATLAB structures but does not import or convert data like BIDS-MATLAB-tools. In theory, BIDS-MATLAB-tools could use BIDS-MATLAB to get the BIDS directory architectures into MATLAB, then convert it to an EEGLAB STUDY. However, in 2021, BIDS-MATLAB could not yet import all the relevant EEG, MEG, and iEEG files. 

[EEG2BIDS](https://github.com/aces/EEG2BIDS) is a Python base executable to format a collection of EDF files to the BIDS format. EEG2BIDS requires users to create JSON files for meta-data. It is a tool designed to archive data as part of a lab protocol where JSON files have been prepared in advance and are suited for technicians organizing data. BIDS-MATLAB-tools export capabilities are more suited for researchers managing their data and are agnostic regarding the original data format.

# Cloning

Make sure you clone with submodules

git clone --recurse-submodules https://github.com/sccn/bids-matlab-tools

# Use with EEGLAB

Simply place the code in the plugin folder of EEGLAB and it will be automatically detected by EEGLAB. See documentation at [https://github.com/sccn/bids-matlab-tools/wiki](https://github.com/sccn/bids-matlab-tools/wiki).

# Version history

v1.0 - initial version

v2.0 - add support for external channel location and fix minor bugs

v3.0 - better export for multiple runs and allowing importing BIDS folder with multiple runs

v3.1 - fix multiple issues at export time including subject numbering

v3.2 - fix menu conflict in EEGLAB with bids validator; check channel types; add option to choose EEG event field; minor bugs

v3.3 - fix issue for Windows and work on GUI

v3.4 - fix issue with saving datasets in memory. Allowing to anonymize participant ID or not. Fixed issue with looking up channel locations.

v3.5 - fix issue with choosing event type in graphic interface; various fixes for GUI edit of BIDS info

v4.0 - fix GUI and many minor export issues

v4.1 - fix issue with JSON

v5.0 - major fixes to import all OpenNeuro EEG datasets

v5.1 - allow calculating dataset meta-data quality

v5.2 - fix issue with history

v5.3 - adding capability to export stimuli

v5.3.1 - update documentation for tInfo.HardwareFilters; fix bug defaults fields not filled for eInfo

v5.4 - fix issue with reading BIDS information when importing BIDS data to STUDY

v6.0 - new examples and fixes for HED

v6.1 - allow data with no events. Fix HED import/export. Fix history.

v7.0 - split code into different functions. Support for behavioral data. Various bug fixes.

v7.2 - fix issue with missing file.

v7.3 - various minor fixes (EEG reference as string; add duration if not present; resave datasets)

v7.4 - fix version issues for HED and BIDS. Export subjects in order. Remove unused columns in participants.tsv file

v7.5 - adding support for coordsystem files, and for loading specific runs, support for motion files
