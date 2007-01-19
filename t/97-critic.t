use Test::More;
eval "use Test::Perl::Critic 0.05 (-profile => 't/perlcriticrc', -severity => 3)";
plan skip_all => "Test::Perl::Critic 0.05 required for testing style" if $@;
plan skip_all => 'set TEST_STYLE to enable this test' unless $ENV{TEST_STYLE};

use strict;
use warnings;

all_critic_ok();
