# bids-matlab-tools

This repository contains a collection of functions to import and export BIDS-formated experiments. The code is tailored for use as an [EEGLAB](http://eeglab.org) plugin but may also be used independently of EEGLAB. Conversion of data format from non-supported BIDS binary format requires that EEGLAB be installed (supported formats are EEGLAB .set files, EDF files, BDF files, and Brain Vision Exchange Format files).

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
