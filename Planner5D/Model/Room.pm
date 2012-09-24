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
	my @roomPoints;
	{
		my $firstWall = shift @walls;
		my @wallPoints = $firstWall->items;
		@roomPoints = @wallPoints;
	}
	while (@roomPoints) {
		my $found;
		my $lastPoint = $roomPoints[-1];
		for my $i (0 .. $#walls) {
			my $wall = $walls[$i];
			my @wallPoints = $wall->items;
			if ($wallPoints[0]->{x} == $lastPoint->{x} &&
					$wallPoints[0]->{y} == $lastPoint->{y}) {
				push @roomPoints, $wallPoints[1];
				splice @walls, $i, 1;
				$found = 1;
				last;
			} elsif ($wallPoints[1]->{x} == $lastPoint->{x} &&
					$wallPoints[1]->{y} == $lastPoint->{y}) {
				push @roomPoints, $wallPoints[0];
				splice @walls, $i, 1;
				$found = 1;
				last;
			}
		}
		last unless $found;
	}

	# Floor or ceiling
	my $z = ($layer eq 'Floor') ? 0 : $self->findParent('h');

	# If polygon is connected, output it
	if ($roomPoints[0]->{x} == $roomPoints[-1]->{x} &&
			$roomPoints[0]->{y} == $roomPoints[-1]->{y}) {
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
	}

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
