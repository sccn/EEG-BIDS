# bids-matlab-tools

This repository contains a collection of function to import and export BIDS-formated experiments. The code is tailored for use in EEGLAB but may also be used independently of EEGLAB. Conversion of data format from non-supported BIDS binary format require that EEGLAB be installed (supported formats are EEGLAB .set files, EDF files, BDF files, and Brain Vision Exchange Format files).

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
