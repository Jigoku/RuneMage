#!/usr/bin/env perl
use strict;
use warnings;
use POSIX;

my $L;

sub experience($)
{
	my $L=shift;
	my $a=0;

	for (my $x=1; $x<$L; $x++)
	{
		$a += floor($x+300*pow(2, ($x/7)));
	}
	return floor($a/4);
}



print experience(84) . "\n";

#for ($L=1; $L<100; $L++) 
#{
#	print 'Level' . $L . ' ' .  experience($L) ."\n";
#}
