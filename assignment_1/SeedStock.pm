#! perl -w
package SeedStock;
use strict;
use warnings;
use Moose;

has 'Seed_stock' => (
    is => 'rw',
    isa => 'Str',
);

has 'Mutant_gene_ID' => (
    is => 'rw',
    isa => 'Gene',	#must be a gene object
);

has 'Last_planted' => (
    is => 'rw',
    isa => 'Str',
);

has 'Storage' => (
    is => 'rw',
    isa => 'Str',
);

has 'Grams_remaining' => (
    is => 'rw',
    isa => 'Int',
);

1;
