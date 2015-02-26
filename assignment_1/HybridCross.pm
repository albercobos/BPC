#! perl -w
package HybridCross;
use strict;
use warnings;
use Moose;

has 'Parent1' => (
    is => 'rw',
    isa => 'SeedStock',	#must be a stock object
);

has 'Parent2' => (
    is => 'rw',
    isa => 'SeedStock',	#must be a stock object
);

has 'F2_Wild' => (
    is => 'rw',
    isa => 'Int',
);

has 'F2_P1' => (
    is => 'rw',
    isa => 'Int',
);

has 'F2_P2' => (
    is => 'rw',
    isa => 'Int',
);

has 'F2_P1P2' => (
    is => 'rw',
    isa => 'Int',
);

1;