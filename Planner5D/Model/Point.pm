package Planner5D::Model::Point;

use strict;
use base 'Planner5D::Model::Object';

sub boundsImpact
{
	return 1;
}

sub bounds
{
	my $self = shift;
	my $offsetX = shift;
	my $offsetY = shift;
	
	# Points claims some free space around
	return (
		$self->{x} + $offsetX - 100,
		$self->{y} + $offsetY - 100,
		$self->{x} + $offsetX + 100,
		$self->{y} + $offsetY + 100
	);
}

1;
