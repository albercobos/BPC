#! perl -w
package StockDB;
use Moose;
use strict;
use warnings;
use SeedStock;

#bonus part 2

#create a new object which is a hash of stock object
has 'Stock_of_seeds' => (
  is => 'rw',
  isa => 'HashRef[SeedStock]',
);

#subroutine that load the file with the stock data into an object
sub load_from_file {
    my ($self,$stock_data_file, $gene_data) = @_;	#arguments of the subroutine
    my %stock_data;	#declare the hash
    
    open(STOCK, "<$stock_data_file") or die "File $stock_data_file could not be opened\n";	#open the file or die
    my @stock_file = <STOCK>;	#store the file into an array and extract the header
    shift(@stock_file);
    
    foreach my $line(@stock_file){	#for each line of the file set the variables with the text separated with the tab 
        my ($seed, $id_gene, $planted, $store, $left) = split "\t", $line;
        chomp ($seed, $id_gene, $planted, $store, $left);	#delete the last character
        my $Gene_Object = $gene_data->{$id_gene};	#set the object gene from the hash of genes
        my $Stock_Object = SeedStock->new(		#create the new object of SeedStock
            Seed_stock => $seed,
            Last_planted => $planted,
            Storage => $store,
            Grams_remaining => $left,
            Mutant_gene_ID => $Gene_Object,	#must be a gene object
        );
        $stock_data{$seed} = $Stock_Object;	#store the object in the hash
    }
    close STOCK;	#close the file
    $self->Stock_of_seeds(\%stock_data);	#return the hash to the program
}

#subroutine that get the stock object with the id
sub get_seed_stock{
  my ($self,$stock)=@_;
  my $Stock_Object=$self->Stock_of_seeds->{$stock};	#get the object from Stock_of_seeds
  return $Stock_Object;
}

#subroutine that write the new database with the new stock data
sub write_database{
  my ($self,$new_stock_data) = @_;	#arguments of the subroutine
  open(OUT, ">$new_stock_data");	#open the file
  
  my $seeds = $self->Stock_of_seeds;	#get the hashref of Stock_of_seeds
  
  print OUT "Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining\n";	#print the header into the file
  foreach my $id (keys%{$seeds}){	#for each of the key of the hash:
     my $Stock_Object=$self->get_seed_stock($id);	#get the object
     print OUT $Stock_Object->Seed_stock . "\t" . $Stock_Object->Mutant_gene_ID->Gene_ID . "\t";	#and print the values of the properties in the file
     print OUT $Stock_Object->Last_planted ."\t" . $Stock_Object->Storage . "\t";
     print OUT $Stock_Object->Grams_remaining . "\n";
  }
  close OUT;	#close the file
}

1;	#exit the package