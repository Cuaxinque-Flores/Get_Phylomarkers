#: VERSION: 2022-12-14
#: LIBRARY: get_phylomarkers_fun_lib
#     * functions called by run_get_phylomarkers_pipeline.sh
#     * part of the GET_PHYLOMARKERS software package
#
#: AUTHORS: Pablo Vinuesa, Center for Genomic Sciences, UNAM, Mexico
#           http://www.ccg.unam.mx/~vinuesa/
#           Bruno Contreras Moreira, EEAD-CSIC, Zaragoza, Spain
#           https://digital.csic.es/cris/rp/rp02661/
#
#: DISCLAIMER: programs of the GET_PHYLOMARKERS package are distributed in the hope that it will be useful, 
#              but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#              See the GNU General Public License for more details. 
#
#: LICENSE: This software is freely available under the GNU GENERAL PUBLIC LICENSE v.3.0
#           see https://github.com/vinuesa/get_phylomarkers/blob/master/LICENSE
#
#: AVAILABILITY: freely available from GitHub @ https://github.com/vinuesa/get_phylomarkers
#                freely available from DockerHub @ https://hub.docker.com/r/vinuesa/get_phylomarkers
#
#: CITATION:
#  Pablo Vinuesa*, Luz Edith Ochoa-S�nchez and Bruno Contreras-Moreira (2018). 
#  GET_PHYLOMARKERS, a software package to select optimal orthologous clusters for phylogenomics 
#  and inferring pan-genome phylogenies, used for a critical geno-taxonomic revision of the genus Stenotrophomonas. 
#  Front. Microbiol. 9:771 | doi: 10.3389/fmicb.2018.00771. | PubMed PMID: 29765358 
#  Software code freely available on GitHub: https://github.com/vinuesa/get_phylomarkers


#---------------------------------------------------------------------------------#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTION DEFINITIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
#---------------------------------------------------------------------------------#

function get_script_PID()
{
    #(( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    # returns the PID of the script, run by USER
    local prog user
    user=$1
    prog=${2%.*} # remove the script's .extension_name
    #proc_ID=$(ps -eaf|grep "$prog"|grep -v grep|grep '-'|grep $USER|awk '{print $2}')
    #proc_ID=$(ps aux|grep "$prog"|grep -v grep|grep '-'|grep $USER|awk '{print $2}')
    proc_ID=$(pgrep -u "$user" "$prog")
    echo "$proc_ID"
    #(( DEBUG > 0 )) && msg "$progname PID is: $proc_ID" DEBUG NC
    
}
#-----------------------------------------------------------------------------------------

function install_Rlibs_msg()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local outfile Rpackage distrodir
   outfile=$1
   Rpackage=$2

   msg " ERROR: the expected outfile $outfile was not produced
            This may be because R package(s) $Rpackage are not properly installed.
            Please run the script './install_R_deps.R' from within \$distrodir to install them.
            Further installation tips can be found in file Rscript install_R_deps.R" ERROR RED

   R --no-save --quiet <<RCMD 2> /dev/null

       print("Your R installation currently searches for packages in :")
       print(.libPaths())
RCMD

# exit 0

}

#-----------------------------------------------------------------------------------------

function count_tree_labels()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   # call R pacake 'ape' to count the number of labels in a tree
   local ext outfile   
   ext=$1
   outfile=$2

   R --no-save --quiet <<RCMD

   pkg <- c("ape")

   local_lib <- c("${distrodir}/lib/R")
   distrodir <-c("$distrodir")

   .libPaths( c( .libPaths(), "${distrodir}/lib/R") )

   library("ape")

   if (!require(pkg, character.only=T, quietly=T)) {
       sprintf("# cannot load %s. Install it in %s using the command 'Rscript install_R_deps.R' from within %s",package,local_lib,distrodir)
       print("Your R installation currently searches for packages in :\n")
       print(.libPaths())
   }

   trees <- list.files(pattern = "$ext\$")
   sink("$outfile")

   for( i in 1:length(trees)){
      tr <- read.tree(trees[i])
      labels <- tr\$tip.label
      no_labels <- length(labels)
      cat(trees[i], "\t", no_labels, "\n")
   }
   sink()
RCMD

   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function count_tree_branches()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local ext outfile   
   ext=$1
   outfile=$2

   (( DEBUG > 0 )) && echo "# running count_tree_branches $ext $outfile"

   R --no-save --quiet <<RCMD &> /dev/null

   local_lib <- c("${distrodir}/lib/R")
   distrodir <- c("$distrodir")

   .libPaths( c(.libPaths(), local_lib) )
   required_packages <- c("ape")

   for (pkg in required_packages) {
     if (!require("ape", character.only=T, quietly=T)) {
       sprintf("# cannot load %s. Install it in %s using the command 'Rscript install_R_deps.R' from within %s",package,local_lib,distrodir)
       print("Your R installation currently searches for packages in :\n")
       print(.libPaths())
     }
   }
   library("ape")

   trees <- list.files(pattern = "$ext\$")
   sink("$outfile")
   cat("#Tree","\t", "n_leaf_lab", "\t", "n_zero_len_br" , "\t", "n_nodes", "\t", "n_br", "\t", "n_int_br", "\t", "n_ext_br", "\t", "is_binary_tree", "\n")

   no_int_br_counter <- 0

   for( i in 1:length(trees)){
      tr <- read.tree(trees[i])
      is_binary_tree <- is.binary.tree(tr)
      #no_branches <- length(tr\$edge.length) # equivalent to the line below
      no_branches <- dim(tr\$edge)[1]

      # we need to count the number of branches with lenght == 0
      # to remove those from the total count of no_branches computed above
      n_zero_length_branches <- length(which(tr\$edge.length == 0))

      # this is the real num. of branches on our tree
      no_branches <- no_branches - n_zero_length_branches

      Nnodes <- tr\$Nnode  # these are the internal nodes
      Ntips <- length(tr\$tip.label) # this is the number of tree labels or taxa

      # this is the number of nodes in a binary tree for n taxa/tip.label
      branches_in_binary_tree <- (2*Ntips - 3)
      #int_branches_in_binary_tree <- branches_in_binary_tree - Ntips

      # Using the eq. above, we can now estimate the real num. of ext branches
      # taking into account the real num of branches, after removing those with zelo length
      no_ext_branches <- floor((no_branches + 3) / 2) # floor() in case there is no real internal branch, we get -0.5
      no_int_branches <- ceiling(no_branches - no_ext_branches) # ceiling() in case there is no real internal branch, we get -0.5
      if ( no_int_branches < 1 ) no_int_br_counter <- no_int_br_counter + 1
      cat(trees[i], "\t", Ntips, "\t", n_zero_length_branches, "\t", Nnodes, "\t", no_branches, "\t", no_int_branches, "\t", no_ext_branches, "\t", is_binary_tree, "\n")
    }
   sink()

   # return this number from function to print in main script
   cat(no_int_br_counter)

RCMD

   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------
function estimate_FT_gene_trees()
{
   # estimate gene trees running FT in parallel using the user-defined thoroughness
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local mol_type search_thoroughness cmd fext basemod n_cores spr spr_length
    
    mol_type=$1
    search_thoroughness=$2
    n_cores=$3
    spr=$4
    spr_length=$5
    
    cmd=''
    fext=''
    basemod=''
   
   if [ "$mol_type" == "DNA" ]
   then
       [ "$search_thoroughness" == "high" ] && FTmod="-quiet -nt -gtr -gamma -bionj -slow -slownni -mlacc 3 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "medium" ] && FTmod="-quiet -nt -gtr -gamma -bionj -slownni -mlacc 3 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "low" ] && FTmod="-quiet -nt -gtr -gamma -bionj -mlacc 2 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "lowest" ] && FTmod="-quiet -nt -gtr -gamma -bionj"
       fext="fasta"
       basemod="GTR"
       cmd="${distrodir}/run_parallel_cmmds.pl $fext '${bindir}/FastTree $FTmod -log \${file%.*}.log < \$file > \${file%.*}_FT${basemod}.ph' $n_cores"
   else
       [ "$search_thoroughness" == "high" ] && FTmod="-quiet -lg -gamma -bionj -slow -slownni -mlacc 3 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "medium" ] && FTmod="-quiet -lg -gamma -bionj -slownni -mlacc 3 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "low" ] && FTmod="-quiet -lg -gamma -bionj -mlacc 2 -spr $spr -sprlength $spr_length"
       [ "$search_thoroughness" == "lowest" ] && FTmod="-quiet -lg -gamma -bionj"
       fext="faaln"
       basemod="lg"
      cmd="${distrodir}/run_parallel_cmmds.pl $fext '${bindir}/FastTree $FTmod -log \${file%.*}.log < \$file > \${file%.*}_FT${basemod}.ph' $n_cores"
   fi

   # NOTE: to execute run_parallel_cmmds.pl with a customized command, resulting from the interpolation of multiple varialbles,
   #	   we have first to save the command line in a variable and pipe its content into bash for execution.
   #       Then we can execute run_parallel_cmmds.pl with a customized command, resulting from the interpolation of multiple varialbles
   (( DEBUG > 0 )) && msg "$cmd" DEBUG NC
   echo "$cmd" | bash &> /dev/null

   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function compute_FT_gene_tree_stats()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local mol_type search_thoroughness parent_PID i N
   mol_type=$1
   search_thoroughness=$2
   parent_PID=$3
   
      
   if [ "$mol_type" == "DNA" ]
   then
       s_type="FTdnaT${search_thoroughness}"

       # parse computation-times and lnL stats for FT-computed gene trees and write to table
       grep '^Gamma20LogLk' ./*.log | cut -f1,2 | sed 's/:Gamma20LogLk//; s/ /\t/' > "FT_lnL_cdnAln_FTGTRG_T${search_thoroughness}.tsv"
       grep '^Total time:' ./*.log | cut -d' ' -f3 > "FT_tot_wc_seconds_cdnAln_FTGTRG_T${search_thoroughness}.tsv"
       
       N=$(find . -name "*.log" | wc -l)
       
       i=0
       for (( i=1; i<=N; i++ )); do
          echo "$s_type" >> s_type.txt
       done
       
       echo -e "alignment\tlnL\twc_secs\s_type" > FT_gene_tree_stats.header
   
       if [ -s "FT_lnL_cdnAln_FTGTRG_T${search_thoroughness}.tsv" ] && [ -s "FT_tot_wc_seconds_cdnAln_FTGTRG_T${search_thoroughness}.tsv" ] && [ -s s_type.txt ]
       then
            # paste src files into table
	    paste "FT_lnL_cdnAln_FTGTRG_T${search_thoroughness}.tsv" "FT_tot_wc_seconds_cdnAln_FTGTRG_T${search_thoroughness}.tsv" s_type.txt > \
	    "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv"
	    check_output "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv" "$parent_PID"
        
	    # add header
	    cat "FT_gene_tree_stats.header" "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv" > t && \
	    mv t "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv"
	
	    # cleanup
	    rm FT_gene_tree_stats.header "FT_lnL_cdnAln_FTGTRG_T${search_thoroughness}.tsv" "FT_tot_wc_seconds_cdnAln_FTGTRG_T${search_thoroughness}.tsv" s_type.txt
       fi
    else
        s_type="FTprotT${search_thoroughness}"

       # parse computation-times and lnL stats for FT-computed gene trees and write to table
       grep '^Gamma20LogLk' ./*cluo.log | cut -f1,2 | sed 's/:Gamma20LogLk//; s/ /\t/' > "FT_lnL_protAln_FTlgG_T${search_thoroughness}.tsv"
       grep '^Total time:' ./*cluo.log | cut -d' ' -f3 > "FT_tot_wc_seconds_protAln_FTlgG_T${search_thoroughness}.tsv"
       
       N=$(find . -name "*.log" | wc -l)
       
       i=0
       for (( i=1; i<=N; i++ )); do
          echo "$s_type" >> s_type.txt
       done
       
       echo -e "alignment\tlnL\twc_secs\ts_type" > FT_gene_tree_stats.header
   
       if [ -s "FT_lnL_protAln_FTlgG_T${search_thoroughness}.tsv" ] && [ -s "FT_tot_wc_seconds_protAln_FTlgG_T${search_thoroughness}.tsv" ] && [ -s s_type.txt ]
       then
            # paste src files into table
	    paste "FT_lnL_protAln_FTlgG_T${search_thoroughness}.tsv" "FT_tot_wc_seconds_protAln_FTlgG_T${search_thoroughness}.tsv" s_type.txt > \
	    "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv"
	    check_output "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv" "$parent_PID"
        
	    # add header
	    cat FT_gene_tree_stats.header "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv" > k && mv k "FT_${mol_type}_gene_tree_T${search_thoroughness}_search_stats.tsv"
	
	    # cleanup
	    rm FT_gene_tree_stats.header "FT_lnL_protAln_FTlgG_T${search_thoroughness}.tsv" "FT_tot_wc_seconds_protAln_FTlgG_T${search_thoroughness}.tsv" s_type.txt
       fi
    fi
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

estimate_IQT_gene_trees()
{
   # estimate gene trees running IQT in parallel using the user-defined mset
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local cmd fext mol_type search_thoroughness
   mol_type=$1
   search_thoroughness=$2
   #IQT_models=$3

   if [ "$mol_type" == "DNA" ]
   then
       [ "$search_thoroughness" == "high" ] && IQTmod="-s \$file -st $mol_type -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "medium" ] && IQTmod="-s \$file -st $mol_type -mset K2P,HKY,TN,TNe,TIM,TIMe,TIM2,TIM2e,TIM3,TIM3e,TVM,TVMe,GTR -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "low" ] && IQTmod="-s \$file -st $mol_type -mset K2P,HKY,TN,TNe,TVM,TVMe,TIM,TIMe,GTR -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "lowest" ] && IQTmod="-s \$file -st $mol_type -mset K2P,HKY,TN,TNe,TVM,TIM,GTR -m MFP -T 1 -alrt 1000 -fast"
       fext="fasta"
       cmd="${distrodir}/run_parallel_cmmds.pl $fext '${bindir}/iqtree $IQTmod'"
       (( DEBUG > 0 )) && msg "DNA IQT_gene_trees command: $cmd" DEBUG NC
   else
       [ "$search_thoroughness" == "high" ] && IQTmod="-s \$file -st $mol_type -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "medium" ] && IQTmod="-s \$file -st $mol_type -mset JTT,LG,PMB,VT,WAG -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "low" ] && IQTmod="-s \$file -st $mol_type -mset LG,VT,WAG -m MFP -T 1 -alrt 1000 -fast"
       [ "$search_thoroughness" == "lowest" ] && IQTmod="-s \$file -st $mol_type -mset LG -m MFP -T 1 -alrt 1000 -fast"
       fext="faaln"
       cmd="${distrodir}/run_parallel_cmmds.pl $fext '${bindir}/iqtree $IQTmod'"
       (( DEBUG > 0 )) && msg "PROT IQT_gene_trees command: $cmd" DEBUG NC
   fi

   # NOTE: to execute run_parallel_cmmds.pl with a customized command, resulting from the interpolation of multiple varialbles,
   #	   we have first to save the command line in a variable and pipe its content into bash for execution.
   #       Then we can execute run_parallel_cmmds.pl with a customized command, resulting from the interpolation of multiple varialbles
   (( DEBUG > 0 )) && msg " > $cmd | bash &> /dev/null" DEBUG NC
   echo "$cmd" | bash &> /dev/null
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function compute_IQT_gene_tree_stats()
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local mol_type search_thoroughness i N
    mol_type=$1
    search_thoroughness=$2
      
    [ "$mol_type" == "DNA" ] && s_type="IQTdnaT${search_thoroughness}"
    [ "$mol_type" == "PROT" ] && s_type="IQTprotT${search_thoroughness}"
   
    # prepare temporal header
    echo -e "model\tcount" > model_count_header.tmp

    # generate computation-time, lnL and best-model stats for IQT-computed gene trees
    grep '^Total wall-clock' ./*log | cut -d: -f1,3 | perl -pe 's/:\h+/\t/; s/\s+sec.*$//'  > tot_wcsecs_IQT_mset_gtrees.tsv
    grep '^Total CPU time used' ./*log | cut -d: -f1,3 | perl -pe 's/:\h+/\t/; s/\s+sec.*$//'  > tot_CPUsecs_IQT_mset_gtrees.tsv
    grep '^BEST SCORE' ./*log | sort -nrk5 | cut -d: -f1,3 | perl -pe 's/\h+/\t/; s/://' > sorted_IQT_lnL_mset_gene_trees.tsv
    grep '^BEST SCORE' ./*log | cut -d: -f1,3 | perl -pe 's/\h+/\t/; s/://' > sorted_by_FILE_NAME_lnL_mset_gene_trees.tsv
    grep '^Best-fit model' ./*log | cut -d' ' -f1,3 | perl -pe 's/:\S+/\t/' > IQT_best_models_for_gene_tree.tsv
    cut -f2 IQT_best_models_for_gene_tree.tsv | sort | uniq -c | awk 'BEGIN{OFS="\t"}{print $2,$1}' > IQT_best_model_counts_for_gene_trees.tsv
    
    cat model_count_header.tmp IQT_best_model_counts_for_gene_trees.tsv > k && mv k IQT_best_model_counts_for_gene_trees.tsv
    [ -s IQT_best_model_counts_for_gene_trees.tsv ] && rm model_count_header.tmp
    
    [ -s s_type.txt ] && rm s_type.txt
    N=$(find . -name "*.log" | wc -l)
    i=0
    for (( i=1; i<=N; i++ )); do
       echo "$s_type" >> s_type.txt
    done

    echo -e "alignment\twc_secs\tCPU_secs\tlnL\tmodel\ts_type" > IQT_gene_tree_stats.header
   
    if [ -s tot_wcsecs_IQT_mset_gtrees.tsv ] && [ -s tot_CPUsecs_IQT_mset_gtrees.tsv ] && [ -s sorted_by_FILE_NAME_lnL_mset_gene_trees.tsv ] && \
     [ -s IQT_best_models_for_gene_tree.tsv ] && [ -s s_type.txt ]
    then
    	# paste src files into table
    	paste tot_wcsecs_IQT_mset_gtrees.tsv tot_CPUsecs_IQT_mset_gtrees.tsv sorted_by_FILE_NAME_lnL_mset_gene_trees.tsv IQT_best_models_for_gene_tree.tsv s_type.txt > \
    	"IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv"
    	check_output "IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv" "$parent_PID"
    
    	# fix columns and add header
    	cut -f1,2,4,6,8,9 "IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv" > k && mv k "IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv"
    	cat IQT_gene_tree_stats.header "IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv" > k && mv k "IQT_${mol_type}_gene_tree_T${search_thoroughness}_stats.tsv"

    	# cleanup
    	rm tot_wcsecs_IQT_mset_gtrees.tsv tot_CPUsecs_IQT_mset_gtrees.tsv sorted_by_FILE_NAME_lnL_mset_gene_trees.tsv \
    	IQT_best_models_for_gene_tree.tsv IQT_gene_tree_stats.header s_type.txt
    	rm ./*.ckp.gz
    
    	mkdir iqtree_output_files && mv ./*.iqtree ./*.bionj ./*.mldist ./*model.gz ./*uniqueseq.phy iqtree_output_files
    	[ -d iqtree_output_files ] && tar -czf iqtree_output_files.tgz iqtree_output_files && rm -rf iqtree_output_files
    	check_output iqtree_output_files.tgz "$parent_PID"
    fi
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------
compute_MJRC_tree()
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local ext algo contree_outfile
    
    ext="$1"
    algo="$2"
        
    if [ "$algo" == "F" ]; then
        contree_outfile=FT_MJRC_tree.nwk
	#labelled_contree_outfile=FT_MJRC_tree_ed.nwk
    else
         contree_outfile=IQT_MJRC_tree.nwk   
         #labelled_contree_outfile=IQT_MJRC_tree_ed.nwk   
    fi
    
    cat ./*."${ext}" > alltrees.nwk
    
    [ -s alltrees.nwk ] && iqtree -con alltrees.nwk &> /dev/null 
    [ -s alltrees.nwk.contree ] && mv alltrees.nwk.contree $contree_outfile && rm alltrees.nwk.log
    
    # NOTE: Possible Bug in IQ-TREE v1.6.2 and v1.6.3, 
    #          IQT v1.6.2 and v1.6.3, but not v1.6.1!, cannot compute the mjrc tree from the debug set,
    #          claiming that the number of taxa are different across trees when running with FT ???
    #          There is not problem with the IQ-TREE run on the same sequences...
    #          >>> Therefore check_output was changed for simple warning messages to avoid premature exit <<<
    [ ! -s "$contree_outfile" ] && msg " >>> Warning, $contree_outfile was not produced!" WARNING LRED
    [ -s "$contree_outfile" ] && msg " >>> Wrote file $contree_outfile ... " PROGR GREEN
    (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
    
    #"$distrodir"/add_labels2tree.pl "$top_dir"/tree_labels.list $contree_outfile &> /dev/null
    # check_output "$labelled_contree_outfile"
}

# NOTE: this consense-based version does not work if trees have different number of nodes! Use iqtree-based function above
#function compute_MJRC_tree()
#{
#     (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
#
#     src_tree_ext=$1
#    
#     # 1 compute MJRE consensus tree with consense; 
#     #   >>> WATCH OUT! does not work with trees with different number of leaves
#     cat ./*$src_tree_ext > intree
#     echo "y" > consense.cmd
#
#     consense < consense.cmd
#     check_output outtree "$parent_PID"
#
#      #5.5 concatenated prefix required by run compute_suppValStas_and_RF-dist.R
#      #ln -s outtree concatenated.ph
#
#     #5.6 compute average bipartition support values for each gene tree
#     #	 and their RF-fistance to the consensus tree computed with consense
#   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
#}
#-----------------------------------------------------------------------------------------

function run_ASTRAL()
{
   # estimate species trees from multiple source gene trees
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local gene_trees num_markers tree_labels_dir
   gene_trees=$1
   num_markers=$2
   tree_labels_dir=$3

   (( DEBUG > 0 )) && msg " > java -jar $distrodir/ASTRAL/astral.jar -i $gene_trees -o astral_species_tree.tre 2> astral.log" DEBUG NC
   java -jar "$distrodir"/ASTRAL/astral.jar -i "$gene_trees" -o astral_top"${num_markers}"geneTrees.sptree 2> astral.log
   check_output "astral_top${num_markers}geneTrees.sptree" "$parent_PID"
   "${distrodir}"/add_labels2tree.pl "${tree_labels_dir}"/tree_labels.list "astral_top${num_markers}geneTrees.sptree" &> /dev/null
   check_output "astral_top${num_markers}geneTrees_ed.sptree" "$parent_PID"
   [ -s "astral_top${num_markers}geneTrees.sptree" ] && rm "astral_top${num_markers}geneTrees.sptree"
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function process_IQT_species_trees_for_molClock()
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC    
    (( DEBUG > 0 )) && caller 0
    local best_search_base_name best_tree_file top_markers_dir no_top_markers
    best_search_base_name=$1
    best_tree_file=$2
    top_markers_dir=$3
    no_top_markers=$4
    
    (( DEBUG > 0 )) && msg "Received: best_search_base_name:$best_search_base_name | best_tree_file:$best_tree_file ..." DEBUG NC     
    # cp the treefile $top_markers_dir for compute_suppValStas_and_RF-dist.R
    mv "${best_search_base_name}.treefile" "${best_tree_file}" && cp "${best_tree_file}" "$top_markers_dir"

    # label the species tree
    print_start_time && msg "# Adding labels back to ${best_tree_file} ..." PRGR BLUE
    (( DEBUG > 0 )) && msg " > ${distrodir}/add_labels2tree.pl ${tree_labels_dir}/tree_labels.list ${best_tree_file} &> /dev/null" DEBUG NC
    "${distrodir}"/add_labels2tree.pl "${tree_labels_dir}"/tree_labels.list "${best_tree_file}" &> /dev/null
    check_output "${best_tree_file}" "$parent_PID"

    rm ./*.ckp.gz concat_cdnAlns.fnainf
    mkdir iqtree_output_files || { msg "ERROR: mkdir iqtree_output_files failed!" ERROR RED && exit ; }
    mv ./*.iqtree ./*.bionj ./*.mldist ./*.uniqueseq.phy "${best_tree_file}" iqtree_output_files
 
    "$distrodir"/rename.pl 's/_ed\.treefile/_ed\.sptree/' ./*_ed.treefile
    [ -d iqtree_output_files ] && cp iqtree_output_files/"${best_tree_file}" .
    cp ./*_ed.sptree sorted_IQ-TREE_searches.out "$top_markers_dir"
    
    [ -d iqtree_output_files ] && tar -czf iqtree_output_files.tgz iqtree_output_files && rm -rf iqtree_output_files
    check_output iqtree_output_files.tgz "$parent_PID"

    cd "$top_markers_dir" || { msg "ERROR: cannot cd into $top_markers_dir!" ERROR RED && exit ; }
    rm concat_cdnAlns.fnainf.treefile 
    #rename 's/\.treefile/\.ph/' ./*.treefile

    #best_tree_file=$(ls ./concat_nonRecomb_KdeFilt_cdnAlns_iqtree_*_ed.ph)
    #ln -s ${best_tree_file} ${best_tree_file%.*}.treefile
     
    # run compute RF-dist to species tree 
    (( DEBUG > 0 )) && echo "running compute_suppValStas_and_RF-dist.R in " && pwd
    print_start_time && msg "# computing the mean support values and RF-distances of each gene tree to the concatenated tree ..." PROGR BLUE
    (( DEBUG > 0 )) && msg " > ${distrodir}/compute_suppValStas_and_RF-dist.R $top_markers_dir 2 fasta treefile 1 &> /dev/null" DEBUG NC
    "${distrodir}"/compute_suppValStas_and_RF-dist.R "$top_markers_dir" 2 fasta treefile 1 &> /dev/null
    
    check_output gene_trees2_concat_tree_RF_distances.tab "$parent_PID"
    
    # remove the unlabeled concat*treefile species tree required for compute_suppValStas_and_RF-dist.R
    # to avoid interference with clock-test, if required
    [ -s gene_trees2_concat_tree_RF_distances.tab ] && rm concat_*.treefile
    
    # need to remove the double extension name and change treefile for ph to make it paup-compatible, if clock-test is to be run
    "${distrodir}"/rename.pl 's/\.fasta\.treefile/\.ph/' ./*.fasta.treefile
    
    # top100_median_support_values4loci.tab should probably not be written in the first instance
    [ -s top100_median_support_values4loci.tab ] && (( no_top_markers < 101 )) && rm top100_median_support_values4loci.tab

   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function concat_alns()
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local aln_ext pPID
    aln_ext=$1
    pPID=$2

    ls -1 ./*"${aln_ext}" > list2concat
    check_output list2concat "$parent_PID"

    if [ "$mol_type" == "DNA" ]
    then
        concat_file="concat_cdnAlns.fna"
    fi

    if [ "$mol_type" == "PROT" ]
    then
        concat_file="concat_protAlns.faa"
    fi

    "${distrodir}"/concat_alignments.pl list2concat > "$concat_file"
    #concat_alignments.pl list2concat > $concat_file
    check_output "$concat_file" "$pPID"
    perl -ne 'if (/^#|^$/){ next }else{print}' "$concat_file" > k && mv k "$concat_file"
    (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function fix_fastaheader()
{
   # extract the relevant fields from the long '|'-delimited fasta headers generated by get_homologues
   # to construct a shorte one, suitable for display as tree labels
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local file
   file=$1
   awk 'BEGIN {FS = "|"}{print $1, $2, $3}' "$file" | 
     perl -pe 'if(/^>/){s/>\S+/>/; s/>\h+/>/; s/\h+/_/g; s/,//g; s/;//g; s/://g; s/\(//g; s/\)//g}' > "${file}ed";

   check_output "${file}ed" "$parent_PID"
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function get_critical_TajD_values()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local no_seq
   no_seq=$1
   TajD_low=$(awk -v n="$no_seq" '$1 == n' "${distrodir}"/pop_gen_tables/TajD_predicted_CIs.tsv|cut -d' ' -f2)
   TajD_up=$(awk -v n="$no_seq" '$1 == n' "${distrodir}"/pop_gen_tables/TajD_predicted_CIs.tsv|cut -d' ' -f3)
   echo "$TajD_low $TajD_up"
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function get_critical_FuLi_values()
{
   (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
   (( DEBUG > 0 )) && caller 0
   local no_seq
   no_seq=$1
   FuLi_low=$(awk -v n="$no_seq" 'BEGIN{FS="\t"}$1 == n' "${distrodir}"/pop_gen_tables/Fu_Li_predicted_CIs.tsv|cut -f2)
   FuLi_up=$(awk -v n="$no_seq" 'BEGIN{FS="\t"}$1 == n'  "${distrodir}"/pop_gen_tables/Fu_Li_predicted_CIs.tsv|cut -f3)
   echo "$FuLi_low $FuLi_up"
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------

function check_output()
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local outfile pPID
    outfile=$1
    pPID=$2

    if [ -s "$outfile" ]
    then
         msg " >>> wrote file $outfile ..." PROGR GREEN
	 return 0
    else
        echo
	msg " >>> ERROR! The expected output file $outfile was not produced, will exit now!" ERROR RED
        echo
	exit 9
	(( DEBUG > 0 )) && msg "check_output running: kill -9 $pPID" DEBUG NC
	kill -9 "$pPID"
    fi
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}

#-----------------------------------------------------------------------------------------
function check_IQT_DNA_models
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    # https://unix.stackexchange.com/questions/299217/grepping-array-from-file-and-reusing-search-pattern
    # https://stackoverflow.com/questions/21058210/use-grep-on-array-to-find-words
    # https://www.linuxquestions.org/questions/linux-newbie-8/split-a-string-into-array-in-bash-869196/

    # NOTE: DNA substitution models changed substantially between IQ-TREE version 1.5.6 and 1.6.1
    local model_string modelOK usr_models dna_models u m
    model_string="$1"
    modelOK=0
    #usr_models=($(echo "$model_string" | tr "," " "))
    # SC2207 requires 4.4+, must not be in posix mode, may use temporary files
    # mapfile -t array < <(mycommand)
    mapfile -t usr_models < <( (echo "$model_string" | tr "," " ") )

    dna_models=(JC F81 K2P HKY TrN TNe K3P K81u TPM2 TPM2u TPM3 TPM3u TIM TIMe TIM2 TIM2e TIM3 TIM3e TVM TVMe SYM GTR)

    for u in ${usr_models[*]}
    do
        for m in ${dna_models[*]}
	do
	    if echo "$u" | grep "$m" &> /dev/null
	    then
		 modelOK=1
		 break
	    fi
	done

        if [ "$modelOK" -ne "1" ]
        then
           msg "ERROR: model $u is not available in IQ-TREE" ERROR RED
	   print_help
	   exit 1
        fi
	modelOK=0
    done
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}

#-----------------------------------------------------------------------------------------
function check_IQT_PROT_models
{
    (( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0

    # https://unix.stackexchange.com/questions/299217/grepping-array-from-file-and-reusing-search-pattern
    # https://stackoverflow.com/questions/21058210/use-grep-on-array-to-find-words
    # https://www.linuxquestions.org/questions/linux-newbie-8/split-a-string-into-array-in-bash-869196/

    # NOTE: protein matrixes changed substantially between IQ-TREE version 1.5.6 and 1.6.1
    local model_string modelOK usr_models dna_models u m
    model_string="$1"
    modelOK=0
    #usr_models=( $(echo "$model_string" | tr "," " ") )
    # SC2207 requires 4.4+, must not be in posix mode, may use temporary files
    # mapfile -t array < <(mycommand)
    mapfile -t usr_models < <( (echo "$model_string" | tr "," " ") )
    
    dna_models=(BLOSUM62 cpREV Dayhoff DCMut FLU HIVb HIVw JTT JTTDCMut LG mtART mtMAM mtREV mtZOA Poisson PMB rtREV VT WAG)

    for u in ${usr_models[*]}
    do
        for m in ${dna_models[*]}
	do
	    if echo "$u" | grep "$m" &> /dev/null
	    then
		 modelOK=1
		 break
	    fi
	done

        if [ "$modelOK" -ne "1" ]
        then
           msg "ERROR: model $u is not available in IQ-TREE" ERROR RED
	   print_help
	   exit 1
        fi
	modelOK=0
    done
   (( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}

#-----------------------------------------------------------------------------------------
function msg()
{
    #(( DEBUG > 0 )) && msg " => working in ${FUNCNAME[0]}  ..." DEBUG NC
    (( DEBUG > 0 )) && caller 0
    local msg mtype col
    msg=$1
    mtype=$2
    col=$3

    NC='\033[0m'

    case $col in
       RED) col='\033[0;31m';;
       LRED) col='\033[1;31m';;
       GREEN) col='\033[0;32m';;
       YELLOW) col='\033[1;33m';;
       BLUE) col='\033[0;34m';;
       LBLUE) col='\033[1;34m';;
       CYAN) col='\033[0;36m';;
       NC) col='\033[0m';;
    esac

    case $mtype in
       HELP)  printf "\n${col}%s${NC}\n\n" "$msg" >&2;;
       ERROR)  printf "\n${col}%s${NC}\n\n" "$msg" >&2 | tee -a "${logdir}/get_phylomarkers_run_${dir_suffix}_${TIMESTAMP_SHORT}.log";;
       WARNING) printf "${col}%s${NC}\n" "$msg" >&1 | tee -a "${logdir}/get_phylomarkers_run_${dir_suffix}_${TIMESTAMP_SHORT}.log";;
       PROGR)  printf "${col}%s${NC}\n" "$msg" >&1 | tee -a "${logdir}/get_phylomarkers_run_${dir_suffix}_${TIMESTAMP_SHORT}.log";;
       DEBUG)  printf "${col}%s${NC}\n" "$msg" >&1 | tee -a "${logdir}/get_phylomarkers_run_${dir_suffix}_${TIMESTAMP_SHORT}.log";;
       VERBOSE)  printf "${col}%s${NC}\n" "$msg" >&1 | tee -a "${logdir}/get_phylomarkers_run_${dir_suffix}_${TIMESTAMP_SHORT}.log";;
    esac
   #(( DEBUG > 0 )) && msg " <= exiting ${FUNCNAME[0]}  ..." DEBUG NC
}
#-----------------------------------------------------------------------------------------
