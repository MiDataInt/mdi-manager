
# Michigan Data Interface

The Michigan Data Interface (MDI) is a framework for developing,
installing and running a variety of HPC data analysis pipelines
and interactive R Shiny data visualization applications
within a standardized design and implementation interface.

## Organization and contents

### MDI code stages

Data analysis in the MDI is logically separated
into two stages of code execution called Stage 1 HPC **pipelines**
and Stage 2 web applications (i.e., **apps**).

### Repository contents

This is the repository for the **MDI manager** utility.
It will help you install and run the interface on your server,
desktop or laptop computer. Functions initialize Stage 1 pipeline
execution and help launch the Stage 2 web apps.

See these repositories for the pipelines and apps frameworks:

https://github.com/MiDataInt/mdi-pipelines-framework

https://github.com/MiDataInt/mdi-apps-framework

## Quick start on the Michigan Great Lakes cluster

If you will be working as an end user on Great Lakes, you
don't need to follow the instructions below. Instead,
FINAL INSTRUCTIONS HERE.

## Installation and Use

### System requirements

The Michigan Data Interface is an R Shiny-based web server.
Accordingly R must be installed on the host machine. See:

https://www.r-project.org/

We recommend updating to the most recent stable R release prior
to installing the interface. Similar to Bioconductor, code
versions are tied to specific releases of R (hint: you can install
multiple R versions on your computer).

### Install the server manager and framework

Install the R package created by this repository from within an
R console using the following commands. They install 'remotes',
which is used to install the 'mdi-manager' R package, which in turn  
is used to install the data analysis suites.

```
install.packages('remotes')
remotes::install_github('MiDataInt/mdi-manager')
mdi::install()
```

The first two steps are relatively quick and will give you access
to the install and run functions, which are similar to
how BiocManager helps you install version-controlled Bioconductor
packages.

<code>mdi::install()</code> handles many R packages and it
will take a while for all of them to be installed the first time,
especially if you are working on a platform where they are compiled
from source code (e.g., Linux). See <code>?mdi::install</code> if you
would like to install somewhere other than your home directory and
for other options.

### Run the MDI web server

Once installed, running the web server is as easy as (see
<code>?mdi::run</code> for additional options):

```
R
mdi::run()
```

Alternatively, you can use the 'mdi' command line helper utility
to launch the web server without using an R console:

```
mdi server
```

Either way, in a few seconds, a web browser will open and you will be 
ready to load your data and run an associated Stage 2 app.

### Configure the available pipelines and apps

<code>mdi::install()</code> will download a standard series
pipelines and apps supported by Michigan core facilities. You can
add any other, custom or non-standard pipelines and/or apps suites
by editing file 'config.yml' in the 'mdi' directory.
You should then call <code>mdi::install()</code> again to configure 
any new package dependencies, or, from the command line:

```
mdi reinstall
```

## Troubleshooting

**<code>mdi::install()</code>**

**Problem**: "Warning: cannot remove prior installation of package ‘xxxx’" and/or
"Warning: packages ‘xxx’ ... are in use and will not be installed".

**Solution**: You were already running the web server (or another Shiny app)
from your R session. Please start from a freshly opened R console when
(re-)installing the interface.


**Problem**: On Windows, R reports "There are binary versions available but the
source versions are later" and then appears to hang.

**Solution**: Actually, a popup window opened that is
prompting you for an answer. It is fine to say "no", you do not need to compile.


**Problem**: Installing all the packages is taking a looooong time!

**Solution**: It always takes many minutes to complete the installation.
However, one factor, especially on large packages such as cpp11 and BH,
that makes it unusually slow is if you are installing to a network drive.
A high speed local disk drive will be faster and is recommended. 


**<code>mdi::run()</code>**

**Problem**: "namespace ‘xxxx’ #.## is already loaded, but >= #.## is required".

**Solution**: You were already running the web server (or another Shiny app)
from your R session. Please start from a freshly opened R console when
starting the web server.
