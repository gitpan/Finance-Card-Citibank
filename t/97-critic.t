use Test::More;
eval "use Test::Perl::Critic 0.05";
plan skip_all => "Test::Perl::Critic 1.00 required for testing style" if $@;
plan skip_all => 'set TEST_STYLE to enable this test' unless $ENV{TEST_STYLE};

use strict;
use warnings;

use Test::Perl::Critic (-profile => 't/perlcriticrc', -severity => 3);
all_critic_ok();
