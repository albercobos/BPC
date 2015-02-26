#! perl -w
package Gene;
use strict;
use warnings;
use Moose;

#set the properties of the Gene package

has 'Gene_ID' => (
    is => 'rw',
    isa => 'Str',
    trigger => sub{ 	#bonus part
      my ($self, $id)=@_; 	#arguments of the subroutine that is execute every time a gene object is stored
      unless ($id=~/A[Tt]\d[Gg]\d{5}/){die "$id is not a Arabidopsis gene identifier\n";}	#unless the identifier match the arabidopsis identifier one exit the program
    } 
);

has 'Gene_name' => (
    is => 'rw',
    isa => 'Str',
);

has 'Mutant_phenotype' => (
    is => 'rw',
    isa => 'Str',
);

has 'Linkage_To' =>(
  is => 'rw',
  isa => 'ArrayRef[Gene]', 	#must be an array ref of the gene
  predicate => 'has_linkage',
);

1;