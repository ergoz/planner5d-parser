#!/usr/bin/perl

use lib ($0 =~ /(.*)\/.+/) ? $1 : '.';
use strict;
use Planner5D::Parser;
use Planner5D::Povray;

my $data = join '', <STDIN>;
my %options = (
	debug => 1
);

my $parser = Planner5D::Parser->new(%options);
my $root = $parser->parse_string($data);

if (my @cls = $parser->unknownClasses) {
	print STDERR "Warning: Unknown classes ignored during convert: " . join(', ', @cls) . "\n";
}

my $povray = Planner5D::Povray->new(%options);
print $povray->povCamera($root);
print $povray->povObserverLight($root);
print $povray->povSunsetLight($root);
print $povray->povGrass($root);
print $povray->povScene($root);
