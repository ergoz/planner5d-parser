package Planner5D::Model::Wall;

use strict;
use base 'Planner5D::Model::Object';

sub isWall
{
	return 1;
}

sub pov
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;

	return '' if $layer ne 'Walls';

	my $h = $self->findParent('h');
	my $w = $self->{w};
	my ($p1, $p2) = $self->items;

	# Calculate wall center, length and angle
	my $cx = ($p1->{x} + $p2->{x}) / 2;
	my $cy = ($p1->{y} + $p2->{y}) / 2;
	my $len = sqrt(
		($p2->{x} - $p1->{x}) ** 2 +
		($p2->{y} - $p1->{y}) ** 2
	) + $w;
	my $angle = atan2(
		$p2->{y} - $p1->{y},
		$p2->{x} - $p1->{x}
	) * 180 / 3.1415926;
	$angle = sprintf('%.3f', $angle) + 0;

	# Render and rotate a wall box
	my $result;

	# Wall itself
	$result .= 'box{<'. (-$len/2) . ',' . (-$w/2) . ',0>,<' . ($len/2) . ',' . ($w/2) . ',' . $h . '>';
	my $basePath = $povray->{storage}->{basePath};
	$result .= qq| texture{pigment{image_map{jpeg "$basePath/textures/bricks.jpg" interpolate 2}} scale 100 rotate <90,0,0> finish {diffuse 0.5}}|;
	$result .= qq| rotate <0,0,$angle>|;
	$result .= qq| translate <$cx,$cy,0>}\n|;

	# Internal wall side
	$result .= 'box{<' . (-$len/2+0.01) . ',' . ($w/2) . ',0>,<' . ($len/2-0.01) . ',' . ($w/2+1) . ',' . $h . '>';
	my $wtexture = $self->findParent('wtexture');
	my $texture = $povray->{downloader}->getTexturePath($wtexture . '.jpg');
	my $reflection = 0;
	my $specular =
		($wtexture =~ /tile/) ? 1 :
		0;
	$result .= qq| texture {pigment{image_map{jpeg "$texture" interpolate 2}} scale 100 rotate <90,0,0> finish{diffuse 1 specular $specular reflection $reflection}}|;
	$result .= qq| rotate <0,0,$angle>|;
	$result .= qq| translate <$cx,$cy,0>}\n|;
}

1;
