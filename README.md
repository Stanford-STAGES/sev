# SEV
Polysomnography sleep analysis toolbox for MATLAB

## Background

This repository was forked from www.github.com/informaton/sev.  Please see the [wiki](https://github.com/informaton/sev/wiki) there for instructions.

## Getting started

With MATLAB installed, set its current folder to the root of this repository and run:

```matlab
sev
```

SEV sets up its supporting paths and opens the graphical interface. Sample sleep study files are available in [tutorial](tutorial/).

For scripts that use SEV functions without opening the interface, run `sev_pathsetup` first. See the [API overview](documentation/API.md) and [EDF loading guide](documentation/loadEDF.md).

## Repository layout

- `+detection/`: event detection algorithms.
- `+filter/`: signal filtering functions.
- `classes/`: application classes for the interface, settings, and data handling.
- `figures/`: MATLAB GUI figures and callbacks.
- `auxiliary/` and `utility/`: supporting functions, including file loading.
- `tutorial/`: sample EDF sleep study and accompanying scoring files.
- `documentation/`: API and usage documentation.

## Researchers

If you would like to cite this software, please use:

> Hyatt E. Moore IV & Emmanuel Mignot (2015) SEV – a software toolbox for large scale analysis and visualization of polysomnography data,
> Computer Methods in Biomechanics and Biomedical Engineering: Imaging & Visualization, 3:3, 123-135, DOI: 10.1080/21681163.2014.891076

