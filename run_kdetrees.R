#!/usr/bin/env -S Rscript --slave

# run_kdetrees.R

VERSION <- 'Version: 0.4.0_2024-04-01'  # check for outlier trees and quit if non are found
                 #v0.3 20Oct22 with portable shebang line
                 # runs kdetrees(all.trees.raw, distance = "dissimilarity", topo.only = TRUE &  topo.only = FALSE)
AUTHOR <- "Authors: Pablo Vinuesa [CCG-UNAM], Bruno Contreras Moreira [EEAD-CSIC]; "
REPOS <- "https://cloud.r-project.org"

# find script path 
cmd.args <- commandArgs()
m <- regexpr("(?<=^--file=).+", cmd.args, perl=TRUE)
script.dir <- dirname(regmatches(cmd.args, m))

LOCAL_LIB = paste(script.dir,"/lib/R",sep = "")
.libPaths( c( .libPaths(), LOCAL_LIB) )

# Note: development made on Tenerife@/home/vinuesa/Projects/marfil/PHYLOMARK/Enterobacter_MLSA_primers_Jan16/F2P_primers/dna_amps

#--------------------------------
#>>>>> FUNCTION DEFINITIONS <<<<<
#--------------------------------
print_help <- function(){
  cat("", VERSION, AUTHOR, "",
      ">>> USAGE: ~/R_code/scripts/run_kdetrees.R <src trees extension name> <file_with_multiple_input_newick_trees> <real; outlier detection tuning parameter [def: k=1.5; less is more stringent]",
      "",
      ">>> AIM: runs the non-parametric kdetrees test to find discordant phylogenetic trees using dist=dissimilarity and topo.only = TRUE & topo.only = FALSE",
      "     assumes trees are generated by the multispecies coalescent distribution and detects outlier trees that are unlikely produced by this distribution",
      "",
      ">>> OUTPUT: Returns diagnostic plots of the kernel density estimates (kde), along with a csv file with kde values and test results (ok|outlier), 
            for both topo.only = TRUE and topo.only = FALSE. Also writes summary stat text files",
      "",
      ">>> NOTES:",
      "# 1. ARGUMENTS:",
      " src tree extension names should be different from that of the file holding them all; e.g. <ph> vs <all_trees.tre>",
      "",
      ">>> ASSUMPTIONS ON DATA:",
      " runs kdeobj.diss.topo <- kdetrees(all.trees.raw, distance = \"dissimilarity\", topo.only = TRUE & topo.only = FALSE )",
      " which does not complain if trees are not rooted or have different number of terminals",
      "",
      ">>> REFERENCE: Weyenberg et al. 2014. Bioinformatics: 30(16):2280-2287; PMID:24764459",
      "",
      ">>> TODO:",
      "1. Integrate with compute_suppValStasts_and_RF-dist.R to provide a single dataframe for amplicon quality evaluation!",
      "2. To achieve 1, put this script into a function and run from within the previous script",
      "3. Need to explore the possibilities offered by package distory",
      "4. Add runmodes; runmode==1 could be an evaluation of k=0.75, 1, 1.25 and 1.5",
      "   An additional runmode could be used to get the good alns for phylogenomics (aln->concat->FastTree)",
      "   Alternatively or in addition to 1., this script sould be called from run_core_genome_FT_WAGGphylo.sh",
      "   by parsing the file kde_dfr_file_all_trees.tre.csv",
      "5. refactor code into subrutines for easier calling from other scripts",
      "6. Add getoptLong; see https://cran.r-project.org/web/packages/GetoptLong/index.html",
      "   or simply optparse: https://cran.r-project.org/web/packages/optparse/index.html",
      "",
      sep ="\n")
}
#-----------------------------------------------------------------------

# see http://www.inside-r.org/r-doc/base/file.copy
# for details on file manipulation from R
checkFileCreated <- function(F){
  if( file.exists(F) ){
    message("File ", F, " was created ...")
  }else{
    warning("File ", F,  " could not be written to disk!")
  }
} 
#-----------------------------------------------------------------------
run_kdetrees_diss_topo <- function(tf, k = 1.5)
{
  # compute kernel density estimate of input tree topology distribution  
  # using (distance = "dissimilarity", topo.only = TRUE)
  # trees do not require to be rooted
  #
  # ARGS: 
  #   tf = multinewick file name holding multiple newick strings/trees
  #   k  = the outlier sensintitivity constant: less is more sensitive (detects more outliers); historical default = 1.5
  # Returns:
  #   a kdeobj.diss.topo object
  fun_name <- "run_kdetrees_diss_topo"
  if (missing(tf))
  {
    stop(" Function ", fun_name, " requires a file name holding multiple newick strings/trees")
  }
  
  kdeobj.diss.topo <- kdetrees(tf, distance = "dissimilarity", k=k, topo.only = TRUE )
  return(kdeobj.diss.topo)
}
#-----------------------------------------------------------------------
run_kdetrees_diss_bl <- function(tf, k = 1.5)
{
  # compute kernel density estimate of input tree distribution with branch lengths
  # using (distance = "dissimilarity", topo.only = FALSE)
  # trees do not require to be rooted
  #
  # ARGS: 
  #   tf = multinewick file name holding multiple newick strings/trees
  #   k = the outlier sintitivity constant: less is more sensitive (detects more outliers); historical default = 1.5
  # Returns:
  #   a kdeobj.diss.topo object
  fun_name <- "run_kdetrees_diss_bl"
  if (missing(tf))
  {
    stop(" Function ", fun_name, " requires a file name holding multiple newick strings/trees")
  }
  
  kdeobj.diss.bl <- kdetrees(tf, distance = "dissimilarity", k=k, topo.only = FALSE )
  return(kdeobj.diss.bl)
}
#-----------------------------------------------------------------------
run_kdetrees_k_check <- function(tf, k_vec = c(0.75, 1, 1.25, 1.5))
{
  # get the kdeobj using distance = "dissimilarity", topo.only = TRUE; trees do not require to be rooted
  #kdeobj <- kdetrees(all.trees.raw, distance = "dissimilarity", topo.only = TRUE )
  fun_name <- "run_kdetrees_k_check"
  if (missing(tf))
  {
    stop(" Function ", fun_name, " requires a file name holding multiple newick strings/trees")
  }
  
  for (i in k_vec)
  {
    kde_obj <- paste("kdeobj.diss.topo.", i, sep="")
    kde_obj <- run_kdetrees_diss_topo(trees_file, i)
    
    
    return(kdeobj.diss.topo)
  }  
}
#-----------------------------------------------------------------------

#####################
##### MAIN CODE #####
#####################

#-------------------------
#>>>>> GET USER ARGS <<<<<
#-------------------------
argv <- commandArgs(TRUE)

if(length(argv) < 2)
{
  print_help()
  stop(" Usage: <src trees extension names> <file_with_multiple_input_newick_trees> <real; outlier detection tuning parameter [def: k=1.5; less is more stringent]")
}

tree_ext <- as.character(argv[1])
input_trees_file <- as.character(argv[2])
if(length(argv) == 2)
{
  k.in <- 1.5
}else{ k.in <- as.numeric(argv[3]) }

message("#>>> Running with arguments: ", tree_ext, " ", input_trees_file, " k=", k.in, " ...")

#--------------------------
#>>>>> LOAD LIBRARIES <<<<<
#--------------------------
# see ?kdetrees for more info on the function
# see help(package=kdetrees)
library("stringr")
library("ape")
library("kdetrees")
library("vioplot")

# initialize vars
no.tips.vec <- c()
no.tips.dfr <- c()
col.vec.topo <- c()
flag.vec.topo <-c()
flag.vec.bl <-c()
combined.flag.vec.bl.topo <- c()
kde_bl_topo_test <-c()

# 1. get the list of tree files
# >>> pass the tree_ext arg to list.files() funct as a regex
rgx <- paste("\\.", tree_ext, "$", sep= "")
files <- list.files(pattern=rgx)

# check there are tree files with tree_ext extension in the working directory
if(length(files) == 0) stop("There are no tree files with ", tree_ext, " extension in the working directory! Will stop now ...")

# save old par() to reset after manipulating it for the plots
opar <- par(no.readonly = TRUE)

# Need to find out how to create a multiphylo object by directly reading in multiple trees
# like from files; may need tree.names = files
#for (i in files){
#  all.trees.raw <- read.tree(file=files[i], tree.names = files, keep.multi = TRUE )
#}

# read all trees from a concatenated file holding them all
# system("cat *.ph > all_trees.raw.tre")
all.trees.raw <- read.tree(file=input_trees_file)

# get the kdeobj using distance = "dissimilarity", topo.only = TRUE; trees do not require to be rooted
#kdeobj <- kdetrees(all.trees.raw, distance = "dissimilarity", topo.only = TRUE )

kdeobj.diss.bl <-run_kdetrees_diss_bl(all.trees.raw, k.in)
kdeobj.diss.topo <-run_kdetrees_diss_topo(all.trees.raw, k.in)
#kdeobj.diss.topo <- kdetrees(all.trees.raw, distance = "dissimilarity", k=k.in, topo.only = TRUE )
#kdeobj.diss.bl <- kdetrees(all.trees.raw, distance = "dissimilarity", k=k.in, topo.only = FALSE )

# print overview stats
kde_stats_file <- paste("kde_stats_", input_trees_file, ".out", sep = "")
sink(file = kde_stats_file, type=c("output"))
kdeobj.diss.bl
kdeobj.diss.topo
sink()

checkFileCreated(kde_stats_file)

# These lines, using dist=geodesic do not work; require rooting
#kdeobj.geod.bl <- kdetrees(all.trees.raw, distance = "geodesic", outgroup= "Cronobacter_sakazakii_ATCC_BAA-894", topo.only = FALSE )
#kdeobj.geod.topo <- kdetrees(all.trees.raw, distance = "geodesic", outgroup="Cronobacter_sakazakii_ATCC_BAA-894", topo.only = TRUE )
# print overview stats
#kdeobj.geod.bl
#kdeobj.geod.topo

# make parallel boxplots 
svg(file="parallel_bxplots_kdeDensity_dist_dissim_topo_TRUE-FALSE.svg")
layout(matrix( c(1,2), 1, 2, byrow = TRUE) )
boxplot(kdeobj.diss.topo$density, main="dist=dissim., topo.only=T")
boxplot(kdeobj.diss.bl$density, main="dist=dissim., topo.only=F")
dev.off()
par(opar)

checkFileCreated("parallel_bxplots_kdeDensity_dist_dissim_topo_TRUE-FALSE.svg")

# print the bad files to screen
topo.outlier.tree.idx <- kdeobj.diss.topo$i
message("there are ", length(topo.outlier.tree.idx), " outlier trees")
num_topo_outlier_trees <- length(topo.outlier.tree.idx)

bl.outlier.tree.idx <- kdeobj.diss.bl$i
message("there are ", length(bl.outlier.tree.idx), " outlier trees")
num_bl_outlier_trees <- length(bl.outlier.tree.idx)

total_outlier_trees <- num_topo_outlier_trees + num_bl_outlier_trees

# create a color vector, to plot the good tree points in blue and outliers in black
src.tree.idx = 1:length(all.trees.raw)
col.vec.topo <- src.tree.idx %in% topo.outlier.tree.idx
col.vec.topo <- ifelse(col.vec.topo, col.vec.topo <- c("black"), col.vec.topo <- c("blue"))

col.vec.bl <- src.tree.idx %in% bl.outlier.tree.idx
col.vec.bl <- ifelse(col.vec.bl, col.vec.bl <- c("black"), col.vec.bl <- c("blue"))

# create plot of kde density points and a boxplot summarithing their distribution
# Note the use of fig= for fine control of placement
svg(file="dotplot_and_bxplot_kdeDensity_dist_dissim_topo_TRUE.svg")
#layout(matrix( c(1,2), 1, 2, byrow = TRUE) )
main_txt <- paste("dist=dissim., topo.only=T, k=", k.in, sep = "")
par(fig=c(0, 0.9, 0, 0.5))
plot(kdeobj.diss.topo$density, col = col.vec.topo, main = main_txt )

# notice the use of new=T; otherwise the boxplot would wipe out the 1st plot!

par(fig=c(0.75, 1, 0, 0.5), new=T) 
boxplot(kdeobj.diss.topo$density, col = col.vec.topo, axes=FALSE, main="k=1.5")

main_txt <- paste("dist=dissim., topo.only=F, k=", k.in, sep = "")
par(fig=c(0, 0.9, 0.5, 1), new = T)
plot(kdeobj.diss.bl$density, col = col.vec.bl, main = main_txt )

par(fig=c(0.75, 1, 0.5, 1), new=T) 
boxplot(kdeobj.diss.bl$density, col = col.vec.bl, axes=FALSE, main="k=1.5")

dev.off()
par(opar)

checkFileCreated("dotplot_and_bxplot_kdeDensity_dist_dissim_topo_TRUE.svg")

# print the outlier files to 
kde_outlier_files <- paste("kde_outlier_files_", input_trees_file, ".out", sep = "")
sink( file = kde_outlier_files, type=c("output") )
message("# These are the outlier trees using dist=dissimilarity and topo.only=T, with k = ", k.in)
files[topo.outlier.tree.idx]
message("===============================================================================================")
message("# These are the outlier trees using dist=dissimilarity and topo.only=F, with k = ", k.in)
files[bl.outlier.tree.idx]
sink()

checkFileCreated(kde_outlier_files)

if (total_outlier_trees == 0){

	q(save = "no", status = 0)

	#kde_dfr_file_*.tab file not written -> checked in main script   

}else {

	# construct a dataframe
	flag.vec.topo <- src.tree.idx %in% topo.outlier.tree.idx
	flag.vec.topo <- ifelse(flag.vec.topo, flag.vec.topo <- c("outlier"), flag.vec.topo <- c("ok")) 

	flag.vec.bl <- src.tree.idx %in% bl.outlier.tree.idx
	flag.vec.bl <- ifelse(flag.vec.bl, flag.vec.bl <- c("outlier"), flag.vec.bl <- c("ok")) 

	#flag.vec.topo.comb <- src.tree.idx %in% topo.outlier.tree.idx
	#flag.vec.bl.comb <- src.tree.idx %in% bl.outlier.tree.idx
	#combined.flag.vec.bl.topo <- unique(union(flag.vec.topo.comb, flag.vec.bl.comb))
	#combined.flag.vec.bl.topo <- ifelse(combined.flag.vec.bl.topo, combined.flag.vec.bl.topo <- c("outlier"), combined.flag.vec.bl.topo <- c("ok")) 
	
	kde.densities.vec.topo <- kdeobj.diss.topo$density
	kde.densities.vec.bl <- kdeobj.diss.bl$density
	
	#kde.trees.dfr <- data.frame(file=files, kde_topo_dens=kde.densities.vec.topo, kde_topo_test=flag.vec.topo, kde_bl_dens=kde.densities.vec.bl, kde_bl_test=flag.vec.bl, kde_bl_topo_test=combined.flag.vec.bl.topo)
	kde.trees.dfr <- data.frame(file=files, kde_topo_dens=kde.densities.vec.topo, kde_topo_test=flag.vec.topo, kde_bl_dens=kde.densities.vec.bl, kde_bl_test=flag.vec.bl)
	
	# Genarate a new variable kde_bl_topo_test, that combines the outilers found by both kde_topo_test & kde_bl_test 
	kde.trees.dfr <- within(kde.trees.dfr, {
	  kde_bl_topo_test[kde_topo_test == "ok" & kde_bl_test == "ok"] <- "ok"
	  kde_bl_topo_test[kde_topo_test == "outlier"] <- "outlier"
	  kde_bl_topo_test[kde_bl_test == "outlier"] <- "outlier"
	})

	# write kde.trees.dfr to file:
	kde_dfr_file <- paste("kde_dfr_file_", input_trees_file, ".tab", sep = "")
	write.table(kde.trees.dfr, file=kde_dfr_file, row.names = FALSE, sep = "\t", quote = FALSE)
	checkFileCreated(kde_dfr_file)
	
	# make histograms to summarize distributions of tree KDEs
	# 1. get colors
	# http://stackoverflow.com/questions/21858394/partially-color-histogram-in-r
	# Here's the method I mentioned in comments:
	# Make some test data (you should do this in your question!)
	# test = runif(10000,-2,0)
	# get R to compute the histogram but not plot it:
	# h = hist(test, breaks=100,plot=FALSE)
	# Your histogram is divided into three parts:
	# ccat = cut(h$breaks, c(-Inf, -0.6, -0.4, Inf))
	# plot with this palette, implicit conversion of factor to number indexes the palette:
	# plot(h, col=c("white","green","red")[ccat])
	
	topo.cutoff <- max(kde.trees.dfr$kde_topo_dens[kde.trees.dfr$kde_topo_test == "outlier"])
	h.topo <- hist(kde.trees.dfr$kde_topo_dens, breaks = 50, plot=FALSE) # probability = TRUE, <== does not like it!?
	ccat.topo <- cut(h.topo$breaks, c(-Inf, topo.cutoff, Inf) )
	
	bl.cutoff <- max(kde.trees.dfr$kde_bl_dens[kde.trees.dfr$kde_bl_test == "outlier"])
	h.bl <- hist(kde.trees.dfr$kde_bl_dens, breaks = 50, plot=FALSE) # probability = TRUE, <== does not like it!?
	ccat.bl <- cut(h.bl$breaks, c(-Inf, bl.cutoff, Inf) )
	
	hist_plot_file <- paste("kde_hist_plot_file_", input_trees_file, ".svg", sep = "")
	svg(file=hist_plot_file)
	layout(matrix( c(1,2), 2, 1, byrow = TRUE) )
	plot(h.topo, main="kde topo", col=c("black", "blue")[ccat.topo])
	rug(jitter(kde.trees.dfr$kde_topo_dens))
	#lines(density(kde.trees.dfr$kde_topo_dens), lwd=2)
	plot(h.bl, main="kde bl", col=c("black", "blue")[ccat.bl])
	rug(jitter(kde.trees.dfr$kde_bl_dens))
	#lines(density(kde.trees.dfr$kde_bl_dens), lwd=2)
	dev.off()
	
	checkFileCreated(hist_plot_file)
	
	# make violin plots to summarize distributions of tree KDEs
	violin_plot_file <- paste("violin_plot_file_", input_trees_file, ".svg", sep = "")
	svg(file=violin_plot_file)
	layout(matrix( c(1,2), 2, 1, byrow = TRUE) )
	vioplot( kde.trees.dfr$kde_bl_dens, col="gold", names = c("kde for tree distributions with branch lengths") ) 
	vioplot( kde.trees.dfr$kde_topo_dens, col="gold", names = c("kde for topology distributions") ) 
	dev.off()
	
	checkFileCreated(violin_plot_file)
	
	# Try doing a consensus;
	# Error in FUN(X[[i]], ...) : one tree has a different number of tips
	# consensus(good.trees, p = 0.5)
	
	
	# exit without saving workspace
	# https://stackoverflow.com/questions/52871579/stop-r-script-with-exit-status-0
	q(save = "no", status = 0)
}
