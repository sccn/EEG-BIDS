# bids-matlab-tools

This repository contains a collection of function to import and export BIDS-formated experiments. The code is tailored for use in EEGLAB but may also be used independently of EEGLAB. Conversion of data format from non-supported BIDS binary format require that EEGLAB be installed (supported formats are EEGLAB .set files, EDF files, BDF files, and Brain Vision Exchange Format files).

# Use with EEGLAB

Simply place the code in the plugin folder of EEGLAB and it will be automatically detected by EEGLAB.

# Export datasets to BIDS

Because there is so much meta-data in BIDS, exporting a collection of dataset to BIDS is currently best done from the command line. An documented example script ''bids_export_example.m'' is provided. You may modify this script for your own purpose. A menu ''To BIDS folder structure'' is available for EEGLAB studies but EEGLAB will not be able to provide important meta-data it does not have access to (such as Authors of the study and other data information). A comprehensive export graphic interface is in development.

# Import datasets from BIDS to EEGLAB study

The EEGLAB menu to import a BIDS dataset into an EEGLAB study is fully functional. A screen capture is shown below.

# Version history

v1.0 - initial version

v2.0 - add support for external channel location and fix minor bugs

