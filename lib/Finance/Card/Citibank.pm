package Finance::Card::Citibank;

###########################################################################
# Finance::Card::Citibank
# Mark V. Grimes
#
# Check you credit card balances.
# Copyright (c) 2005 Mark V. Grimes (mgrimes@cpan.org).
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# Formatted with tabstops at 4
#
# Parts of this package were inspired by:
#   Simon Cozens - Finance::Bank::Lloyds module
# Thanks!
#
###########################################################################

use strict;
use warnings;

use Carp;
use WWW::Mechanize;

our $VERSION = '1.61';

our $ua = WWW::Mechanize->new(
    env_proxy => 1, 
    keep_alive => 1, 
    timeout => 30,
); 


sub check_balance {
    my ($class, %opts) = @_;
    my $self = bless { %opts }, $class;
    my $content;

    if( $opts{content} ){
        # If we give it a file, use the file rather than downloading
        local $/;
        open my $fh, "<", $opts{content} or die;
        $content = <$fh>;
        close $fh;
    } else {
        croak "Must provide a password" unless exists $opts{password};
        croak "Must provide a username" unless exists $opts{username};

        $ua->get("http://www.citicards.com/cards/wv/home.do") 
            or die "couldn't load the initial page";

        $ua->submit_form(
            form_name 	=> 'LOGIN',
            fields		=> {
                    'USERNAME'	    => $opts{username},
                    'PASSWORD'	    => $opts{password},
                    'NEXT_SCREEN'   => '/AccountSummary',
                },
        ) or die "couldn't submit the login form";

        $ua->submit_form(
            form_number => 2,
        ) or die "couldn't submit the account selection form";
        $content = $ua->content;
    }
	
	if( $opts{log} ){
        # Dump to the filename passed in log
		open( my $fh,">", $opts{log});
		print $fh $ua->content;
		close $fh;
	}

    # TODO: deal with multiple accounts... seems to use js to get other accounts?
	my @accnts = $content =~
		m!
          <span\sclass="prodName"><a\sname="hide1c"></a>(.*?)</span></td>\s*
          </tr>\s*
          <tr>\s*
          <td>&nbsp;(Account\sending\sin:\s*\d+)</td>\s*
          .*?
          Current\sBalance.*?
          </tr>\s*
          <tr>\s*
          <td\s[^>]*><div[^>]*><span\sclass="balNdue">\$([\d,\.]+)</span></div></td>
     !xisg;
	warn "couldn't find any accounts" unless @accnts;

	my @accounts;
    while( @accnts ){
        my ($name, $account_no, $balance)
                = ( shift @accnts, shift @accnts, shift @accnts );

        $name       =~ s/&[^;]*;//g;
        $name       =~ s/<[^>]*>//g;
        $account_no =~ s/\s+/ /g;
        $balance    =~ s/,//g;
        $balance    *= -1;
	
        print "Name: $name\n";
        print "Account: $account_no\n";
        print "Balance: $balance\n";

        push @accounts, (bless {
            balance		=> $balance,
            name		=> $name,
            sort_code	=> $account_no,
            account_no	=> $account_no,
            # parent		=> $self,
            statement	=> undef,
        }, "Finance::Card::Citibank::Account");
    }

    return @accounts;
}

package Finance::Card::Citibank::Account;
# Basic OO smoke-and-mirrors Thingy
# no strict; 
our $AUTOLOAD;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Card::Citibank - Check your Citigroup credit card accounts from Perl

=head1 SYNOPSIS

  use Finance::Card::Citibank;
  my @accounts = Finance::Card::Citibank->check_balance(
	  username => "xxxxxxxxxxxx",
	  password => "12345",
  );

  foreach (@accounts) {
	  printf "%20s : %8s / %8s : USD %9.2f\n",
	  $_->name, $_->sort_code, $_->account_no, $_->balance;
  }
  
=head1 DESCRIPTION

This module provides a rudimentary interface to Citigroup online
at C<https://www.citibank.com/us/cards/index.jsp>. 
You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed 
for HTTPS support to work. C<WWW::Mechanize> is required.

=head1 CLASS METHODS

=head2 check_balance()

  check_balance( usename => $u, password => $p )

Return an array of account objects, one for each of your bank accounts.

=head1 OBJECT METHODS

  $ac->name
  $ac->sort_code
  $ac->account_no

Return the account name, sort code and the account number. The sort code is
just the name in this case, but it has been included for consistency with 
other Finance::Bank::* modules.

  $ac->balance

Return the account balance as a signed floating point value.

=head1 WARNING

This warning is verbatim from Simon Cozens' C<Finance::Bank::LloydsTSB>,
and certainly applies to this module as well.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens for C<Finance::Bank::LloydsTSB>. The interface to this module,
some code and the pod were all taken from Simon's module.

=head1 TODO

Currently, only the first account is picked up. It is an easy fix (I think)
to grab other accounts, but I don't need it. If someone out there does need
multiple accounts, let me know and I will implement it.

=head1 AUTHOR

Mark V. Grimes <mgrimes@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-7 by mgrimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
