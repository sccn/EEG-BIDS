# JSONio: a MATLAB/Octave JSON library

JSONio is a MATLAB/Octave library to read/write data in the JSON (JavaScript Object Notation) data-interchange format. 
 
* JSON: https://www.json.org/
   
It relies on the JSON parser jsmn written by [Serge Zaitsev](https://zserge.com/):
 
* jsmn: https://zserge.com/jsmn/

This library is also part of SPM:
 
* SPM: https://www.fil.ion.ucl.ac.uk/spm/

## INSTALLATION
 
Simply add the JSONio directory to the MATLAB path:

```matlab
addpath /home/login/Documents/MATLAB/JSONio
```
 
A compiled MEX file is provided for 64-bit MATLAB platforms. It needs to be compiled for Octave with:
 ```
mkoctfile --mex jsonread.c jsmn.c -DJSMN_PARENT_LINKS
 ```
 
## EXAMPLE

```matlab
json = jsonread(filename)

jsonwrite(filename, json)
```
