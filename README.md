![EEG-BIDS](https://github.com/sccn/EEG-BIDS/assets/1872705/47675a55-6573-47d7-abec-48e364d5ad8a)

# EEG-BIDS

The EEG-BIDS (formerly known as **BIDS-MATLAB-tools**) repository contains a collection of functions that import and export BIDS-formated experiments. The code is tailored for use as an [EEGLAB](http://eeglab.org) plugin but may also be used independently of EEGLAB. Conversion of data format from non-supported BIDS binary format requires that EEGLAB be installed (supported formats are EEGLAB .set files, EDF files, BDF files, and Brain Vision Exchange Format files).

# Documentation

Refer to the [wiki documentation](https://github.com/sccn/EEG-BIDS/wiki) or the submenus of this plugin if you are on the EEGLAB website.

# EEG-BIDS vs other BIDS software

[BIDS-MATLAB](https://bids-matlab.readthedocs.io/en/latest/) is a project to import BIDS data. BIDS-MATLAB maps the BIDS directory architectures to MATLAB structures but does not import or convert data like EEG-BIDS. In theory, EEG-BIDS could use BIDS-MATLAB to get the BIDS directory architectures into MATLAB and then convert it to an EEGLAB STUDY. However, in 2021, BIDS-MATLAB could not yet import all the relevant EEG, MEG, and iEEG files. 

[EEG2BIDS](https://github.com/aces/EEG2BIDS) is a Python-based executable that formatted a collection of EDF files in BIDS format. EEG2BIDS requires users to create JSON files for meta-data. It is a tool designed to archive data as part of a lab protocol where JSON files have been prepared in advance and are suited for technicians organizing data. EEG-BIDS export capabilities are more suited for researchers managing their data and are agnostic regarding the original data format.

[ezBIDS](https://brainlife.io/ezbids/) is a data export tool for MRI and fMRI data. It does not allow to export EEG data to our knowledge.

[data2bids.m](https://www.fieldtriptoolbox.org/example/bids/) is a Fieldtrip function to export BIDS data. This includes EEG and maybe fMRI. This function can only be used from the command line.

[EEG-BIDS](https://github.com/sccn/EEG-BIDS) (this program) is the most popular tool to export EEG data using both a graphical interface and/or command line (more than half of the BIDS datasets on OpenNeuro were exported using EEG-BIDS and it has more than 2200 installs in EEGLAB). A compiled stand-alone version will also be released soon.

# Standalone version

A standalone version of the plugin is available when [downloading EEGLAB](https://sccn.ucsd.edu/eeglab/download.php). The standalone plugin version is distributed with EEGLAB because it uses EEGLAB resources. After download EEGLAB, use the executable named EEGBIDS (Mac) or EEGBIDS.bat (Windows). 

# EEG-BIDS export capabilities

Accepted EEG input formats are all files that EEGLAB can read. 

* EEG export: ✔ (as .set, .edf, .bdf, or .vhmk files)
* iEEG export: ✔ (as .set, .edf or .nwb)
* Eye-tracking export: ✔ (beta)
* HED export: ✔
* BEH export: ✔
* MRI export: ✔ (no conversion)
* fMRI export: ✖
* Motion-cap export: ✖ (upcoming)
* EMG export: ✖ (upcoming)
* MEG export: ✖ (upcoming)

# EEG-BIDS import capabilities for EEGLAB

EEG-BIDS allows importing BIDS datasets into EEGLAB. This is the type of information that can be imported.

* EEG import: ✔ (all formats)
* iEEG import: ✔ (all formats)
* MEG import: ✔ (.ds and .fif files supported, more formats upcoming)
* Eye-tracking import: ✖ (upcoming)
* HED import: ✔
* BEH import: ✔
* MRI import: n/a
* fMRI import: n/a
* Motion-cap import: ✔ (beta)
* EMG import: ✖ (upcoming)

# Cloning

Make sure you clone with submodules

```
git clone https://github.com/sccn/EEG-BIDS
```

# Testing 

Use the EEG-BIDS_testcases repository for testing

```
git clone https://github.com/sccn/EEG-BIDS_testcases.git
```

# Use with EEGLAB

Simply place the code in the EEGLAB plugin folder, and EEGLAB will automatically detect it. See documentation at [https://github.com/sccn/EEG-BIDS/wiki](https://github.com/sccn/EEG-BIDS/wiki).

# Zip command to release plugin

```
zip -r EEG-BIDS8.0.zip EEG-BIDS/* -x /EEG-BIDS/testing/additionaltests/* /EEG-BIDS/testing/ds004117/* /EEG-BIDS/testing/hbn_eye_tracking_data/* /EEG-BIDS/testing/data/*
```

# Version history

v1.0 - initial version

v2.0 - add support for external channel location and fix minor bugs

v3.0 - better export for multiple runs and allowing importing BIDS folder with multiple runs

v3.1 - fix multiple issues at export time, including subject numbering

v3.2 - fix menu conflict in EEGLAB with bids validator; check channel types; add option to choose EEG event field; minor bugs

v3.3 - fix an issue for Windows and work on GUI

v3.4 - fix the issue with saving datasets in memory. Allowing to anonymize participant ID or not. Fixed issue with looking up channel locations.

v3.5 - fix issue with choosing event type in graphic interface; various fixes for GUI edit of BIDS info

v4.0 - fix GUI and many minor export issues

v4.1 - fix the issue with JSON

v5.0 - major fixes to import all OpenNeuro EEG datasets

v5.1 - allow calculating dataset meta-data quality

v5.2 - fix the issue with history

v5.3 - adding the capability to export stimuli

v5.3.1 - update documentation for tInfo.HardwareFilters; fix bug defaults fields not filled for eInfo

v5.4 - fix the issue with reading BIDS information when importing BIDS data to STUDY

v6.0 - new examples and fixes for HED

v6.1 - allow data with no events. Fix HED import/export. Fix history.

v7.0 - split code into different functions. Support for behavioral data. Various bug fixes.

v7.2 - fix the issue with the missing file.

v7.3 - various minor fixes (EEG reference as string; add duration if not present; resave datasets)

v7.4 - fix version issues for HED and BIDS. Export subjects in order. Remove unused columns in participants.tsv file

v7.5 - adding support for coordsystem files, for loading specific runs, support for motion files

v7.6 - adding export to non-EEGLAB formats, refactoring export

v7.7 - fix importing MEG and MEF files. Better handling of runs. Now tracks tool version in BIDS.

v8.0 - renamed files, separate file for task info, adding BIDS statistic output, handling EGI & BVA file better, channel types and units, adding eye-tracking and behavioral support

v9.0 - update json import to conform to BIDS key-level inheritance principle. Support iEEG and MEG export. Support exporting multiple tasks. Fix issues with exporting channel locations. BIDS export wizard.

v9.1 - better handling of behavioral data. Fix issue with task name and BIDS dataset with no README file.

v10.0 - adding support for re-exporting datasets. Adding the the "desc" key. Fix some event export issues.

v10.1 - fix export wizard. 
