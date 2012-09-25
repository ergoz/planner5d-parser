#!/usr/bin/perl

use lib ($0 =~ /(.*)\/.+/) ? $1 : '.';
use strict;
use Planner5D::Downloader;

my $downloader = Planner5D::Downloader->new;
print $downloader->getMeshPath('220') . "\n";
