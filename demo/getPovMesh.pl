#!/usr/bin/perl

use lib ($0 =~ /(.*)\/.+/) ? $1 : '.';
use strict;
use Planner5D::Povray;

my $povray = Planner5D::Povray->new;
print $povray->getPovMeshPath('220') . "\n";
