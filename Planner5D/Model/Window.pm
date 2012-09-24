package Planner5D::Model::Window;

use strict;
use base 'Planner5D::Model::Holes';

sub povTranslate
{
	my $self = shift;
	my $result = Planner5D::Model::Ns::povTranslate($self);
	# Hack. Why windows are not floor-based?
	$result .= qq| translate <0,0,83>|;
	return $result;
}

1;
