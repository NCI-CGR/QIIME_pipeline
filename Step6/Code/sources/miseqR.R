##### FUNCTIONS ########



##### Normalization #######

# Better rounding function than R's base round
myround <- function(x) { trunc(x + 0.5) }


# Scales reads by 
# 1) taking proportions
# 2) multiplying by a given library size of n
# 3) rounding 
# Default for n is the minimum sample size in your library
# Default for round is floor
scale_reads <- function(physeq, n = min(sample_sums(physeq)), round = "floor") {
  
  # transform counts to n
  physeq.scale <- transform_sample_counts(physeq, 
    function(x) {(n * x/sum(x))}
  )
  
  # Pick the rounding functions
  if (round == "floor"){
    otu_table(physeq.scale) <- floor(otu_table(physeq.scale))
  } else if (round == "round"){
    otu_table(physeq.scale) <- myround(otu_table(physeq.scale))
  }
  
  # Prune taxa and return new phyloseq object
  physeq.scale <- prune_taxa(taxa_sums(physeq.scale) > 0, physeq.scale)
  return(physeq.scale)
}


##### ADONIS ###########

# Function to run adonis test on a phyloseq object and a variable from metadata
# Make sure OTU data is standardized/normalized before 
phyloseq_to_adonis <- function(physeq, distmat = NULL, dist = "bray", formula) {
  
  if(!is.null(distmat)) {
    phydist <- distmat
  } else {
    phydist <- phyloseq::distance(physeq, dist)
  }
  
  metadata <- as(sample_data(physeq), "data.frame")
  
  # Adonis test
  f <- reformulate(formula, response = "phydist")
  adonis.test <- adonis(f, data = metadata)
  print(adonis.test)

  # Run homogeneity of dispersion test if there is only 1 variable
  if (grepl("\\+", formula)) {
    l <- list(
      dist = phydist, 
      formula = f, 
      adonis = adonis.test
    )
  } else {
    group <- metadata[ ,formula]
    beta <- betadisper(phydist, group)
    disper.test = permutest(beta)
    print(disper.test)
    
    l <- list(
      dist = phydist, 
      formula = f, 
      adonis = adonis.test, 
      disper = disper.test
    )
  }
  return (l)
}

########## Bar Plots #################

# This function takes a phyloseq object, agglomerates OTUs to the desired taxonomic rank, 
# prunes out OTUs below a certain relative proportion in a sample (ie 1% ) 
# and melts the phyloseq object into long format which is suitable for ggplot stacked barplots.
taxglom_and_melt <- function(physeq, taxrank, prune){
  
  # Agglomerate all otu's by given taxonomic level
  pglom <- tax_glom(physeq, taxrank = taxrank)
  
  # Create a new phyloseq object which removes taxa from each sample below the prune parameter
  pglom_prune <- transform_sample_counts(pglom,function(x) {x/sum(x)})
  otu_table(pglom_prune)[otu_table(pglom_prune) < prune] <- 0
  pglom_prune <- prune_taxa(taxa_sums(pglom_prune) > 0, pglom_prune)
  
  # Melt into long format and sort by taxonomy
  physeq_long <- psmelt(pglom_prune)
  physeq_long <- physeq_long[order(physeq_long[ ,taxrank]), ]

  # Return long data frame
  return(physeq_long)
}


###### Merge functions ############

# Merge samples by averaging OTU counts instead of summing
merge_samples_mean <- function(physeq, group, round){
  # Calculate the number of samples in each group
  group_sums <- as.matrix(table(sample_data(physeq)[ ,group]))[,1]
  
  # Merge samples by summing
  merged <- merge_samples(physeq, group)
  
  # Divide summed OTU counts by number of samples in each group to get mean
  # Calculation is done while taxa are columns
  x <- as.matrix(otu_table(merged))
  if(taxa_are_rows(merged)){ x<-t(x) }

  # Pick the rounding functions
  if (round == "floor"){
    out <- floor(t(x/group_sums))
  } else if (round == "round"){
    out <- myround(t(x/group_sums))
  }
  
  # Return new phyloseq object with taxa as rows
  out <- otu_table(out, taxa_are_rows = TRUE)
  otu_table(merged) <- out
  return(merged)
}

# Merge samples, just including OTUs that were present in all merged samples
# Call this function before running merge_samples()
merge_OTU_intersect <- function(physeq, group){
  
  # Make sure we're not starting with more taxa than we need 
  physeq <- prune_taxa(taxa_sums(physeq) > 0, physeq)
  
  s <- data.frame(sample_data(physeq))
  l <- levels(s[,group])
  o <- otu_table(physeq)
  
  # Loop through each category
  for (cat in 1:length(l)) {
 
    # Get the index of all samples in that category
    w <- which(s[,group]==l[cat])
   
    # subset to just those columns of OTU table
    cat.sub<-o[,w]
    print(dim(cat.sub))
    
    # Find the indices of 0's in the OTU table
    zeros <- apply(cat.sub, 1, function(r) any(r == 0))
    
    # If an OTU had a 0 in at least one sample, change all samples to 0
    cat.sub[zeros,] <- 0
  }
  
  o[,w] <- cat.sub
  otu_table(physeq) <- o
  
  return(physeq)
  
}

  


