# Michigan Data Interface

The [Michigan Data Interface](https://midataint.github.io/) (MDI) is a framework for developing,
installing and running a variety of HPC data analysis pipelines
and interactive R Shiny data visualization applications
within a standardized design and implementation interface.

## Repository contents

Data analysis in the MDI is logically separated into 
[two stages of code execution](https://midataint.github.io/docs/analysis-flow/) 
called Stage 1 HPC **pipelines**
and Stage 2 web applications (i.e., **apps**).

This is the repository for the **MDI manager** utility.
It will help you install and run the MDI on your server,
desktop or laptop computer. Functions initialize Stage 1 pipeline
execution and help launch the Stage 2 web apps.

### Related repositories

Code developers are directed to the following repositories for templates to
**create your own pipelines and apps suites**,

- <https://github.com/MiDataInt/mdi-pipelines-suite-template>
- <https://github.com/MiDataInt/mdi-apps-suite-template>

to this repository if you wish to **run a secure Stage 2 apps 
server** on your own publicly addressable server (e.g, an AWS instance),

- <https://github.com/MiDataInt/mdi-simple-server>

and to these repositories for the pipelines and apps frameworks, if you 
wish to help develop the MDI itself.

- <https://github.com/MiDataInt/mdi-pipelines-framework>
- <https://github.com/MiDataInt/mdi-apps-framework>

## Installation and Use

### System requirements

The MDI manager utility and the Stage 2 web apps are R programs.
Accordingly, R must be installed on the host machine. See:

<https://www.r-project.org/>

We recommend updating to the most recent stable R release prior
to installing the MDI. Similar to [https://www.bioconductor.org/](Bioconductor), 
MDI installations are tied to specific releases of R (hint: you can install
multiple R versions on your computer).

### Install the server manager and framework

Install the R package contained in this repository from within an
R console using the following commands. They install 'remotes',
which is used to install the 'mdi-manager' R package, which in turn  
is used to install the data analysis suites.

```
install.packages('remotes')
remotes::install_github('MiDataInt/mdi-manager')
mdi::install()
```

You will be asked to confirm the MDI installation process, which will
download additional code and write files to your system.

The first two steps are relatively quick and will give you access
to the <code>install()</code> and <code>run()</code> functions, similar to
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

or

```
Rscript -e 'mdi::run()'
```

or on Linux or Mac,

```
mdi run
```

Regardless of how you call <code>mdi::run()</code>, in a few seconds, 
a web browser will open and you will be ready to load your data and run an associated app.

### Configure the available pipelines and apps suites

<code>mdi::install()</code> will download a standard series of
pipelines and apps supported by Michigan core facilities. You can
add any other custom or non-standard pipelines and/or apps suites
by editing file 'config/suites.yml' in the 'mdi' root directory.

```
# mdi/config/suites.yml
suites:
    pipelines:
        - https://github.com/GIT_USER/SUITE_NAME-mdi-pipelines.git
    apps:
        - https://github.com/GIT_USER/SUITE_NAME-mdi-apps.git
```

You should then call <code>mdi::install()</code> again to configure 
any new package dependencies, or, from the command line:

```
mdi install
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
