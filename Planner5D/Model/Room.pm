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
	{
		my $firstWall = shift @walls;
		my @wallPoints = $firstWall->items;
		@roomPoints = @wallPoints;
	}
	while (@roomPoints) {
		my $lastPoint = $roomPoints[-1];
		my ($bestWall, $bestIndex, $bestDist);
		for my $i (0 .. $#walls) {
			my $wall = $walls[$i];
			my @wallPoints = $wall->items;
			for my $index (0, 1) {
				my $point = $wallPoints[$index];
				my $dist = ($point->{x} - $lastPoint->{x}) ** 2 + ($point->{y} - $lastPoint->{y}) ** 2;
				if (!defined($bestDist) || $dist < $bestDist) {
					$bestWall = $i;
					$bestIndex = $index;
					$bestDist = $dist;
				}
			}
		}
		last unless defined $bestWall;
		my ($bestWall) = splice @walls, $bestWall, 1;
		my @wallPoints = $bestWall->items;
		push @roomPoints, $wallPoints[$bestIndex] if $bestDist > 0.1;
		push @roomPoints, $wallPoints[1 - $bestIndex];
	}

	return '' if @roomPoints < 3;

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
