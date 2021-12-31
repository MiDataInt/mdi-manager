# Michigan Data Interface

The [Michigan Data Interface](https://midataint.github.io/) (MDI) 
is a framework for developing, installing and running a variety of 
HPC data analysis pipelines and interactive R Shiny data visualization 
applications within a standardized design and implementation interface.

## Repository contents

Data analysis in the MDI is logically separated into 
[two stages of code execution](https://midataint.github.io/docs/analysis-flow/) 
called Stage 1 HPC **pipelines** and Stage 2 web applications (i.e., **apps**).
Collectively, pipelines and apps are referred to as **tools**.

This is the repository for the R package that comprises the **MDI manager** 
utility. It will help you install and run the MDI on your server,
desktop or laptop computer. Functions initialize Stage 1 pipeline
execution and launch Stage 2 web apps.

Please read the [MDI documentation](https://midataint.github.io/) for 
more information.

## System requirements

The MDI manager and Stage 2 web apps are R programs.
Accordingly, R must be installed on the host machine. See:

<https://www.r-project.org/>

We recommend updating to the latest stable R release prior
to installing the MDI, as MDI installations are tied to specific 
releases of R (hint: you can install multiple R versions on your 
computer).

## Installation

### Indirect installation using other utilities (recommended)

Most users should not manually install the manager package as it is 
installed for you by other wrapper utilities. Please use the 
following links to learn how to:

- [install the MDI in one folder on a host computer](https://github.com/MiDataInt/mdi.git)
- [install the MDI on a public cloud web server](https://github.com/MiDataInt/mdi-web-server.git)
- [install and control a remote or shared MDI installation](https://wilsonte-umich.shinyapps.io/mdi-script-generator)

### Manual installation in R

Developers may wish to execute the following commands from within an R console.
They install 'remotes', which is used to install this 'mdi-manager' R package, 
which in turn installs the data analysis frameworks.

```r
install.packages('remotes')
remotes::install_github('MiDataInt/mdi-manager')
mdi::install()
```

After you confirm the MDI installation process, 
the first two steps are relatively quick and will give you access
to the <code>install()</code> and <code>run()</code> functions.

<code>mdi::install()</code> handles many R packages and it
will take many minutes for them all to be installed the first time,
especially if you are working on a platform where they are compiled
from source code (e.g., Linux). See <code>?mdi::install</code> 
for additional options.

### Configure and install tool suites

<code>mdi::install()</code> clones MDI repositories
that define the pipeline and apps frameworks, but few actual
tools. To install tools from any provider, first edit the file 
'config/suites.yml' in the 'mdi' root directory.

```yml
# mdi/config/suites.yml
suites:
    - https://github.com/GIT_USER/SUITE_NAME-mdi-tools.git
    - GIT_USER/SUITE_NAME-mdi-tools # either format works
```

Then call <code>mdi::install()</code> again to clone the listed
repositories and install any additional R package dependencies.
Repeat these steps any time you need to add a new tool suite
to your MDI installation.

Alternatively, you can edit suites.yml and install new suites
from within the Stage 2 web server, or run the following from the
command line:

```bash
mdi add https://github.com/GIT_USER/SUITE_NAME-mdi-tools.git
mdi add GIT_USER/SUITE_NAME-mdi-tools # either format works
```

## Run the MDI web server

Once installed, run the MDI web server from within R as follows (see
<code>?mdi::run</code> for additional options):

```r
mdi::run()
```

The wrapper utilities linked above can again also call
<code>mdi::run()</code> on your behalf. Regardless of how you do it, 
in a few seconds a web browser will open and you will be ready to 
load your data and run an associated app.

## Troubleshooting

**<code>mdi::install()</code>**

**Problem**: "Warning: cannot remove prior installation of package ‘xxxx’" and/or
"Warning: packages ‘xxx’ ... are in use and will not be installed".

**Solution**: You were already running the web server (or another Shiny app)
from your R session. Please start from a freshly opened R console when
(re-)installing the interface.
<br>
<br>
**Problem**: On Windows, R reports "There are binary versions available but the
source versions are later" and then appears to hang.

**Solution**: Actually, a popup window opened that is
prompting you for an answer. It is fine to say "no", you do not need to compile.
<br>
<br>
**Problem**: Installing all the packages is taking a looooong time!

**Solution**: It always takes many minutes to complete the installation.
However, one factor, especially on large packages such as cpp11 and BH,
that makes it unusually slow is if you are installing to a network drive.
A high speed local disk drive can be much faster and is recommended. 
<br>
<br>
**<code>mdi::run()</code>**

**Problem**: "namespace ‘xxxx’ #.## is already loaded, but >= #.## is required".

**Solution**: You were already running the web server (or another Shiny app)
from your R session. Please start from a freshly opened R console when
starting the web server.
