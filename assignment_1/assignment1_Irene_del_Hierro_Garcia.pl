#! perl -w
use strict;		#modules the programa is going to use
use warnings;
use Moose;
use Gene;
use StockDB;
use HybridCross;

#=======================================MAIN================================

unless ($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3]){ #unless 4 arguments are passed to the script
# print an informative message about the usage of the program
print "\n\n\nUSAGE: perl assignment1.pl gene_information.tsv seed_stock_data.tsv new_stock_data.tsv cross_data.tsv\n\n\n";
exit 0; # and exit
}

#get the 4 filenames
my $gene_data_file = $ARGV[0];		#contains information about genes
my $stock_data_file = $ARGV[1];		#contains information about seeds in the genebank
my $new_stock_data = $ARGV[2];		#outfile when new seed stock is placed
my $cross_data_file = $ARGV[3];		#contains information about crosses that have been made

my $gene_data=&load_gene_data($gene_data_file);		#call load_gene_data subroutine
#gene_data is a hashref $gene_data(Gene_ID)=$Gene_Object

my $stock_data=StockDB->new();		#object created to store the new seed stock
$stock_data->load_from_file($stock_data_file, $gene_data); 	#call load_from_file subroutine
#$stock_data is a hashref of $stock_data(Seed_Stock)=$Stock_Object

&plant_seeds($stock_data, 7);		#current stock data, plant 7 grams
#this lines calls plant_seeds subroutine which updates the status if every seed record in stock_data

$stock_data->write_database($new_stock_data);		#current stock data, new database filenames
#the line above creates the file new_stock_data.tsv with the current status of seeds and dates

&process_cross_data($cross_data_file,$stock_data,$gene_data);		#call process_cross_data subruotine
#the line above test the linkage. The Gene_Object become updated with the others genes they are linked to

print "\n\nFinal Report:\n\n";	

#for each of the genes in the gene data hash
foreach my $gene (keys %{$gene_data}){ 
  if ($gene_data->{$gene}->has_linkage){ 	#only process the Gene Object if it has linked genes
    #has_linkage is a Moose predicate for Linkage_To
    my $gene_name = $gene_data->{$gene}->Gene_name;	#get the name of that gene (property)
    my $LinkedGenes = $gene_data->{$gene}->Linkage_To; 	#get the Gene Objects that are linked to it
    #Linkage_To is a Property of ArrayRef[Gene] with a predicate has_linkage
    foreach my $linked(@{$LinkedGenes}){	#dereference the array, and then for each of the array members
      my $linked_name = $linked->Gene_name; 	# get it's name using the Gene_Name property
      print "$gene_name is linked to $linked_name\n";	# and print the information
    }
  }
}

#===================================SUBROUTINES=========================================================

#subroutine that load the data from gene_data_file
sub load_gene_data {
    my $gene_data_file="$_[0]";		#argument for this subroutine
    my %gene_data;			#hash of data of genes
    
    open(GENE, "<$gene_data_file") or die "$gene_data_file does not exit or could not be opened\n";	#open the file and give a warning message if the program cannot open it
    my @file = <GENE>;	#store the gene_data_file information in an array
    shift(@file);	#extract the header of the file
    
    foreach my $line(@file){		#for each line of the array:
        my ($id_gene, $gene_name, $mut_phenotype) = split "\t", $line;		#extract the text separated between tabs and store each one in a variable
        chomp ($id_gene, $gene_name, $mut_phenotype);			#delete the last character of the line
        my $Gene_Object =Gene->new(		#create a Gene Object with all his properties
            Gene_ID => $id_gene,
            Gene_name => $gene_name,
            Mutant_phenotype => $mut_phenotype,
        );
        $gene_data{$id_gene} = $Gene_Object;	#store the $Gene_Object in a hash and use as the key the Gene_ID
    }
    close GENE;		#close the file
    return \%gene_data;		#return the hash
}

#subroutine that plants seeds
sub plant_seeds{
  my ($stock_data, $amount) =@_;	#arguments for the subroutine: the amount of seed that are going to be planted and the hash of stock_data
   
  my (undef, undef, undef, $mday, $mon, $year) = localtime;	#sentences that can update the time, declare the variables
  $year = $year+1900;		#obtain the current year
  $mon += 1;			#obtain the current month
  if (length($mon) == 1) {$mon = "0$mon";}		#set the month with two digits in case the month have just one
  if (length($mday) == 1) {$mday = "0$mday";}		#set the day with two digits in case the day have just one
  my $today = "$mday/$mon/$year";		#save the current date in the variable $today

  my $seeds = $stock_data->Stock_of_seeds;	#obtain the hashref from Stock_of_seeds
  foreach my $stock(keys%{$seeds}){		#for each element in the hash
    my $Stock_Object=$stock_data->get_seed_stock($stock);	#obtain the object from the hash
    my $left=$Stock_Object->Grams_remaining;			#obtain the grams left from the object
    if($left <= $amount){		#if grams left are less than the amount of grams are going to be planted, set the value of grams to zero 
      $left=0;					#and give a warning message
      print "WARNING: We have run out of Seed Stock $stock\n";	
    }
    else{		#if grams left are not less than the amount of seeds are going to be planted, substract the amount of grams
      $left=$left - $amount;
    }
    $Stock_Object->Grams_remaining($left);	#update the grams of the object
    $Stock_Object->Last_planted($today);	#update the date of the object
  }
}

#subroutine that load the data of the cross_data_file
sub load_cross_data{
  my ($cross_data_file,$stock_data)= @_;	#arguments of the subroutine
  my %cross_data;				#hash that is going to store the information
  
  open(CROSS, "<$cross_data_file") or die "File $cross_data_file could not be opened\n";	#open the file and if the program cannot open it give a warning message
  my @file = <CROSS>; shift(@file);	#store the data of the file in an array and extract the header
  
  my $seeds = $stock_data->Stock_of_seeds;	#get the hashref of the Stock_of_seeds
  
  foreach my $line(@file){		#for each line of the file set the variables with the text separated with the tab
    my ($p1,$p2,$f2,$f2_p1,$f2_p2,$f2_p1p2) = split "\t", $line;
    chomp ($p1,$p2,$f2,$f2_p1,$f2_p2,$f2_p1p2);		#delete the last line character
    
    my $Parent1 = $stock_data->get_seed_stock($p1);	#get the object from each one of the parent
    my $Parent2 = $stock_data->get_seed_stock($p2);
    my $Object_Cross=HybridCross->new(		#create the Cross Object
      Parent1 => $Parent1,
      Parent2 => $Parent2,
      F2_Wild => $f2,
      F2_P1 => $f2_p1,
      F2_P2 => $f2_p2,
      F2_P1P2 => $f2_p1p2,
    );
  
    $cross_data{$p1}{$p2}=$Object_Cross;	#store the object in the hash
  }
  close CROSS;		#close the file
  return \%cross_data;	#return the hash
}

#subroutine that process the cross data
sub process_cross_data{
  my ($cross_data_file,$stock_data) =@_;	#arguments of the subroutine
  my $cross_data = &load_cross_data($cross_data_file,$stock_data);	#calls the subroutine that load the data from the file and give a hashref as output
  
  my $seeds=$stock_data->Stock_of_seeds;	#get the hashref of Stock_of_seeds
  
  foreach my $P1(sort keys %{$cross_data}){		#for each pair of parents in the hash
    foreach my $P2(keys %{$cross_data->{$P1}}){
      my $Object_Cross = $cross_data->{$P1}{$P2};	#set the object from the hash
      my $chi=&calculate_chi($Object_Cross);		#calculate the chi square value from the subroutine
      if($chi>7.815){					#if chi value is higher than 7.815 we accept the linkage between the genes with a 3 freedom degrees
							#and with a probability of 5%
	my $Parent1 =$stock_data->get_seed_stock($P1); 		#get the object for the parent
	my $Parent2 =$stock_data->get_seed_stock($P2); 	  
	my $linked=$Parent1->Mutant_gene_ID;			#set the linked gene for the parent 1 and parent 2 and add the linked one to each of the gene object
	push @{$Parent2->Mutant_gene_ID->{Linkage_To}}, $linked;		#in the property of Linkage_To
	$linked=$Parent2->Mutant_gene_ID;
	push @{$Parent1->Mutant_gene_ID->{Linkage_To}}, $linked;
      }
    }
  }
}

#subroutine that compute the chi square
sub calculate_chi{
  my ($Object_Cross)=@_;	#argument of the subroutine: the cross object
  my $amount=0; my $chi=0;	#set of variables

  my @observed = (		#array that contains the observed values of the offspring
    $Object_Cross->F2_Wild,
    $Object_Cross->F2_P1,
    $Object_Cross->F2_P2,
    $Object_Cross->F2_P1P2
  );
  foreach my $i(@observed){$amount=$amount+$i;}	#calculate the total of offspring

  my @expected = (	#array that contains the expected values
    $amount*(9/16),
    $amount*(3/16),
    $amount*(3/16),
    $amount*(1/16),
  );
  
  my $freedom=scalar(@observed);	#determine the freedom degrees of the test

  #calculate the chi square taking in account the freedom degrees
  for(my $i=0;$i<$freedom;$i++){$chi=$chi+(($observed[$i]-$expected[$i])**2)/$expected[$i];}
#return the chi square
return $chi;
}

exit;	#exit of the program