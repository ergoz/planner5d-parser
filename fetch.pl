#!/usr/bin/perl

use strict;
use LWP::Simple;
use JSON;

binmode STDOUT, ':utf8';

# Process command line
@ARGV == 1 or usage();
my $projectId = $ARGV[0] or usage();
$projectId =~ /^[a-f0-9]{32}$/ or usage();

# Load data
my $content = get("https://planner5d.com/api/project/$projectId");
if (!$content) {
	print STDERR "Error fetching project\n";
	exit 1;
}

# Parse data envelope
eval {
	$content = from_json($content);
};
if ($@) {
	print STDERR "Error parsing data envelope\n";
	exit 1;
}
if ($content->{error}) {
	print STDERR "Could not load given project: $content->{error}\n";
	print STDERR to_json($content, {pretty=>1});
	exit 1;
}

for my $item (@{$content->{items}}) {

	# Prepare filename
	my $name = $item->{name};
	$name =~ s/[^\d\p{Letter}\-\. \-]+/./g;
	$name ||= 'noname';
	my $filename = $name . '.json';

	# Choose not used filenames
	if (-e $filename) {
		my $prefix = $filename . '.';
		my $suffix = 0;
		do {
			$filename = $prefix . $suffix;
			$suffix++;
		} while (-e $filename);
	}

	# Parse content
	eval {
		$content = from_json($item->{data});
	};
	if ($@) {
		print STDERR "Error parsing project data\n";
		exit 1;
	}

	# Output content
	print "Writing $filename...\n";
	open my $f, '>', $filename or die "Could not open $filename: $!\n";
	binmode $f, ':utf8';
	print $f to_json($content, {pretty=>1}) . "\n";
	close $f;
}

sub usage
{
	print STDERR "Usage: $0 <projectId>\n";
	exit 1;
}
