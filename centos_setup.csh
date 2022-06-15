setenv PDKPATH /farmshare/home/classes/ee/372/PDKs/share/pdk/sky130A

setenv PATH /cad/mentor/2019.11/Catapult_Synthesis_10.4b-841621/Mgc_home/bin:$PATH
setenv PATH /cad/iverilog/bin:$PATH
setenv MGLS_LICENSE_FILE 1717@cadlic0.stanford.edu
setenv SRAM_PATH /farmshare/home/classes/ee/372/PDKs/sky130_sram_macros/

module load base
module load vcs
module load lc
module load syn
module load xcelium
module load genus
module load innovus/20.13.000
module load calibre/2019.1
module load prime
module load magic/latest
module load netgen/latest

# export PATH=/cad/openlane/build/bin:$PATH

# Autocomplete for make
complete make \
    'n/-f/f/' \
    'c/*=/f/' \
    'n@*@`cat -s GNUmakefile Makefile makefile |& sed -n -e "/No such file/d" -e "/^[^     #].*:/s/:.*//p"`@'

