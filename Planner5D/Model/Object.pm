package Planner5D::Model::Object;

use strict;

#
# Povray script of all child items
#
sub povItems
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;
	my $result = '';

	# Ouptut all child items
	for my $item ($self->items) {
		$result .= $item->pov($povray, $layer);
	}

	# Shift entire object
	if ($result) {
		my $x = $self->{x};
		my $y = $self->{y};
		my $union = defined($x) && defined($y);
		$result = qq|union {\n${result}translate<$x,$y,0>\n}\n| if $union;
	}

	return $result;
}

#
# Get list of child items
#
sub items
{
	my $self = shift;
	return @{$self->{items}};
}

#
# Render object to povray script
#
sub pov
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;
	return $self->povItems($povray, $layer);
}

#
# Reference to direct parent
#
sub parent
{
	my $self = shift;
	return $self->{parent};
}

#
# Find attribute with given name from any
# of object parents
#
sub findParent
{
	my $self = shift;
	my $att = shift;
	my $cur = $self->parent;
	while ($cur) {
		return $cur->{$att} if defined $cur->{$att};
		$cur = $cur->parent;
	}
	return undef;
}

#
# Whether this object does any impact
# on bounds calculation
#
sub boundsImpact
{
	return 0;
}

#
# Bounding rect
#
sub bounds
{
	my $self = shift;
	my $offsetX = shift;
	my $offsetY = shift;
	my ($x1, $y1, $x2, $y2);
	if ($self->boundsImpact) {
		$x1 = $self->{x} + $offsetX;
		$y1 = $self->{y} + $offsetY;
		$x2 = $self->{x} + $offsetX;
		$y2 = $self->{y} + $offsetY;
	}
	for my $item ($self->items) {
		my ($cx1, $cy1, $cx2, $cy2) = $item->bounds;
		if (defined($cx1)) {
			$cx1 += $self->{x} + $offsetX;
			$cx2 += $self->{x} + $offsetX;
			$cy1 += $self->{y} + $offsetY;
			$cy2 += $self->{y} + $offsetY;
			$x1 = $cx1 if !defined($x1) || $cx1 < $x1;
			$y1 = $cy1 if !defined($y1) || $cy1 < $y1;
			$x2 = $cx2 if !defined($x2) || $cx2 > $x2;
			$y2 = $cy2 if !defined($y2) || $cy2 > $y2;
		}
	}
	return ($x1, $y1, $x2, $y2);
}

#
# Whether this object is a wall
#
sub isWall
{
	return 0;
}

1;
