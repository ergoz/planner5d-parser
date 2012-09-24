package Planner5D::Model::Room;

use strict;
use base 'Planner5D::Model::Object';

sub pov
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;

	my $result = '';
	$result .= $self->povItems($povray, $layer);
	return $result if $layer ne 'Floor' && $layer ne 'Ceiling';

	# Make floor polygon
	my @walls = $self->walls;
	for my $i (0 .. $#walls) {
		my $wall = $walls[$i];
		my @wallPoints = $wall->items;
	}
	my @roomPoints;
	for my $wall (@walls) {
		for my $point ($wall->items) {
			if (!@roomPoints || $roomPoints[-1]->{x} != $point->{x} ||
					$roomPoints[-1]->{y} != $point->{y}) {
				push @roomPoints, $point;
			}
		}
	}

	return '' if @roomPoints < 3;

	if ($roomPoints[0]->{x} != $roomPoints[-1]->{x} ||
			$roomPoints[0]->{y} != $roomPoints[-1]->{y}) {
		push @roomPoints, $roomPoints[0];
	}

	# Floor or ceiling
	my $z = ($layer eq 'Floor') ? 0 : $self->findParent('h');

	# Output polygon
	$result .= qq|polygon{| . scalar(@roomPoints);
	for my $point (@roomPoints) {
		$result .= ',<' . ($self->{x}+$point->{x}) . ',' . ($self->{y}+$point->{y}) . ',' . $z . '>';
	}
	if ($layer eq 'Floor') {
		# Floor is visible but doesn't cast shadows
		my $texture = $povray->{downloader}->getTexturePath($self->{texture} . '.jpg');
		my $reflection =
			($self->{texture} =~ /tile/) ? 0.3 : 0;
		my $specular =
			($self->{texture} =~ /tile/) ? 1 :
			($self->{texture} =~ /laminate/) ? 0.3 :
			0;
		$result .= qq| texture{pigment{image_map{jpeg "$texture" interpolate 2}} finish{diffuse 1 reflection $reflection specular $specular} scale 100}|;
		$result .= qq| no_shadow|;
	} else {
		# Ceiling is invisible, but casts shadows
		$result .= qq| no_image|;
	}

	$result .= qq|}\n|;

	return $result;
}

sub walls
{
	my $self = shift;
	my @walls;
	for my $item ($self->items) {
		push @walls, $item if $item->isWall;
	}
	return @walls;
}

1;
