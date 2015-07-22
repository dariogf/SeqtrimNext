= seqtrimnext

* http://www.scbi.uma.es/downloads

== DESCRIPTION:

SeqtrimNEXT is a customizable and distributed pre-processing software for NGS (Next Generation Sequencing) biological data. It makes use of scbi_mapreduce gem to be able to run in parallel and distributed environments. It is specially suited for Roche 454 (normal and paired-end) & Ilumina datasets, although it could be easyly adapted to any other situation.
 
== FEATURES:

* SeqtrimNEXT is very flexible since it's architecture is based on plugins.
* You can add new plugins if needed.
* SeqtrimNEXT uses scbi_mapreduce and thus is able to exploit all the benefits of a cluster environment. It also works in multi-core machines big shared-memory servers.

== Default templates for genomics & transcriptomics are provided

<b>genomics_454.txt</b>:: cleans genomics data from Roche 454 sequencer.
<b>genomics_454_with_paired.txt</b>:: cleans genomic data from a paired-end experiment sequenced with a Roche 454 sequencer.
<b>low_quality.txt</b>:: trims low quality.
<b>low_quality_and_low_complexity.txt</b>:: trims low quality and low complexity.
<b>transcriptomics_454.txt</b>:: cleans transcriptomics data from a Roche 454 sequencer.
<b>transcriptomics_plants.txt</b>:: cleans transcriptomics data from a Roche 454 sequencer with extra databases for plants.
<b>amplicons.txt</b>:: filters amplicons.
  
== You can define your own templates using a combination of available plugins:

<b>PluginKey</b>:: to remove sequencing keys from 454 input sequences.
<b>PluginMids</b>:: to remove MIDS (barcodes) from 454 sequences.
<b>PluginLinker</b>:: splits sequences into two inserts when a valid linker is found (paired-end experiments only)
<b>PluginAbAdapters</b>:: removes AB adapters from sequences using a predefined DB or one provided by the user.
<b>PluginFindPolyAt</b>:: removes polyA and polyT from sequences.
<b>PluginLowComplexity</b>:: filters sequences with low complexity regions
<b>PluginAdapters</b>:: removes Adapters from sequences using a predefined DB or one provided by the user.
<b>PluginLowHighSize</b>:: removes sequences too small or too big.
<b>PluginVectors</b>:: remove vectors from sequences using a predefined database or one provided by the user.
<b>PluginAmplicons</b>:: filters amplicons using user predefined primers.
<b>PluginIndeterminations</b>:: removes indeterminations (N) from the sequence.
<b>PluginLowQuality</b>:: eliminate low quality regions from sequences.
<b>PluginContaminants</b>:: remove contaminants from sequences or rejects contaminated ones. It uses a core database, but it can be expanded with user provided ones.



== SYNOPSIS:

Once installed, SeqtrimNEXT is very easy to use:
  
To install core databases (it should be done at installation time):

  $> seqtrimnext -i core
  
Databases will be installed nearby SeqtrimNEXT by default, but you can override this location by setting the environment variable +BLASTDB+. Eg.:

If you with your database installed at /var:

  $> export BLASTDB=/var/DB/formatted

Be sure that this environment variable is always loaded before SeqtrimNEXT execution (Eg.: add it to /etc/profile.local).

There are aditional databases. To list them:

  $> seqtrimnext -i LIST

To perform an analisys using a predefined template with a FASTQ file format using 4 cpus:

  $> seqtrimnext -t genomics_454.txt -Q input_file_in_FASTQ -w 4
  
To perform an analisys using a predefined template with a FASTQ file format:
  
  $> seqtrimnext -t genomics_454.txt -f input_file_in_FASTA -q input_file_in_QUAL

To clean illumina fastq files, with paired-ends and qualities encoded in illumina 1.5 format, using 4 cpus and disabling verbose output:

  $> seqtrimnext -t genomics_short_reads.txt -F illumina15 -Q p1.fastq,p2.fastq -w 4 -K

To clean illumina fastq files, with paired-ends and qualities encoded in standard phred format, using 4 cpus and disabling verbose output:

  $> seqtrimnext -t genomics_short_reads.txt  -Q p1.fastq,p2.fastq -w 4 -K

To get additional help and list available templates and databases:

  $> seqtrimnext -h

=== CLUSTERED EXECUTION:

To take full advantage of a clustered installation, you can launch SeqtrimNEXT in distributed mode. You only need to provide it a list of machine names (or IPs) where workers will be launched. 

Setup a workers file like this:
    
    machine1
    machine1
    machine2
    machine2
    machine2

And launch SeqtrimNEXT this way:

    $> seqtrimnext -t genomics_454.txt -Q input_file_in_FASTQ -w workers_file -s 10.0.0
    
This will launch 2 workers on machine1 and 3 workers on machine2 using the network whose ip starts with 10.0.0 to communicate.

  
== TEMPLATE MODIFICATIONS

You can modify any template to fit your workflow. To do this, you only need to copy one of the templates and edit it with a text editor, or simply modify a used_params.txt file that was produced by a previous SeqtrimNEXT execution.
  
Eg.: If you want to disable repetition removal, do this:

1-Copy the template file you wish to customize and name it params.txt.
2-Edit params.txt with a text editor
3-Find a line like this:

remove_clonality = true


4-Replace this line with:

remove_clonality = false

5- Launch SeqtrimNEXT with params.txt file instead of a default template:

  $> seqtrimnext -t params.txt -f input_file_in_FASTA -q input_file_in_QUAL



The same way you can modify any of the parameters. You can find all parameters and their description in any used_params.txt file generated by a previous SeqtrimNEXT execution. Parameters not especified in a template are automatically set to their default value at execution time.

<b>NOTE</b>: The only mandatory parameter is the plugin_list one.

== REQUIREMENTS:

* Ruby 1.9.2 or greater
* CD-HIT 4.5.3 or greater
* Blast plus 2.24 or greater (prior versions have bugs that produces bad results)
* [Optional] - GnuPlot version 4.4.2 or greater (prior versions may produce wrong graphs)
* [Optional] - pdflatex - Optional, to produce a detailed report with results 


== INSTALL:

=== Installing CD-HIT

*Download the latest version from http://code.google.com/p/cdhit/downloads/list
*You can also use a precompiled version if you like
*To install from source, decompress the downloaded file, cd to the decompressed folder, and issue the following commands:

  make
  sudo make install

=== Installing Blast

*Download the latest version of Blast+ from ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
*You can also use a precompiled version if you like
*To install from source, decompress the downloaded file, cd to the decompressed folder, and issue the following commands:

  ./configure
  make
  sudo make install


=== Installing Ruby 1.9

*You can use RVM to install ruby:

Download latest certificates (maybe you don't need them):

  $ curl -O http://curl.haxx.se/ca/cacert.pem 
  $ export CURL_CA_BUNDLE=`pwd`/cacert.pem # add this to your .bashrc or 
equivalent

Install RVM following the directions from this web:

  https://rvm.io/rvm/install
  
Install ruby 1.9.2 (this can take a while):
  
  $ rvm install 1.9.2
  
Set it as the default:

  $ rvm use 1.9.2 --default

=== Install SeqtrimNEXT

SeqtrimNEXT is very easy to install. It is distributed as a ruby gem:

  gem install seqtrimnext
  
This will install seqtrimnext and all the required gems.

=== Install and rebuild SeqtrimNext's core databases

SeqtrimNEXT needs some core databases to work. To install them:

  seqtrimnext -i core
  
You can change default database location by setting the environment variable +BLASTDB+. Refer to SYNOPSIS for an example.

There are aditional databases that can be listed with:

  seqtrimnext -i LIST

=== Database modifications

Included databases will be usefull for a lot of people, but if you prefer, you can modify them, or add more elements to be search against your sequences. 

You only need to drop new fasta files to each respective directory, or even create new directories with new fasta files inside. Each directory with fasta files will be used as a database:

DB/vectors to add more vectors
DB/contaminants to add more contaminants
etc...

Once the databases has been modified, you will need to reformat them by issuing the following command:

  seqtrimnext -c

Modified databases will be rebuilt.


== CLUSTERED INSTALLATION

To install SeqtrimNEXT into a cluster, you need to have the software available on all machines. By installing it on a shared location, or installing it on each cluster node. Once installed, you need to create a init_file where your environment is correctly setup (paths, BLASTDB, etc):

  export PATH=/apps/blast+/bin:/apps/cd-hit/bin
  export BLASTDB=/var/DB/formatted
  export SEQTRIMNEXT_INIT=path_to_init_file
  

And initialize the SEQTRIMNEXT_INIT environment variable on your main node (from where SeqtrimNEXT will be initially launched):

  export SEQTRIMNEXT_INIT=path_to_init_file

If you use any queue system like PBS Pro or Moab/Slurm, be sure to initialize the variables on each submission script. 

<b>NOTE</b>: all nodes on the cluster should use ssh keys to allow SeqtrimNEXT to launch workers without asking for a password.

== SAMPLE INIT FILES FOR CLUSTERED INSTALLATION:

=== Init file

  $> cat stn_init_env 

  source ~latex/init_env
  source ~ruby19/init_env
  source ~blast_plus/init_env
  source ~gnuplot/init_env
  source ~cdhit/init_env

  export BLASTDB=~seqtrimnext/DB/formatted/
  export SEQTRIMNEXT_INIT=~seqtrimnext/stn_init_env


=== PBS Submission script

  $> cat sample_work.sh 
  
  # 40 distributed workers and 1 GB memory per worker:
  #PBS -l select=40:ncpus=1:mpiprocs=1:mem=1gb
  # request 10 hours of walltime:
  #PBS -l walltime=10:00:00
  # cd to working directory (from where job was submitted)
  cd $PBS_O_WORKDIR

  # create workers file with assigned node names

  cat ${PBS_NODEFILE} > workers

  # init seqtrimnext
  source ~seqtrimnext/init_env

  time seqtrimnext -t paired_ends.txt -Q fastq -w workers -s 10.0.0


Once this submission script is created, you only need to launch it with:

  qsub sample_work.sh

=== MOAB/SLURM submission script

  $> cat sample_work_moab.sh

  #!/bin/bash 
  # @ job_name = STN
  # @ initialdir = .
  # @ output = STN_%j.out
  # @ error = STN_%j.err
  # @ total_tasks = 40
  # @ wall_clock_limit = 10:00:00

  # guardar lista de workers
  sl_get_machine_list > workers

  # init seqtrimnext
  source ~seqtrimnext/init_env

  time seqtrimnext -t paired_ends.txt -Q fastq -w workers -s 10.0.0

Then you only need to submit your job with mnsubmit

  mnsubmit sample_work_moab.sh


== LICENSE:

(The MIT License)

Copyright (c) 2011 Almudena Bocinos & Dario Guerrero

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.