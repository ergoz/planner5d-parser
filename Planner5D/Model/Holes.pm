package Planner5D::Model::Holes;

use strict;
use base 'Planner5D::Model::Ns';

sub pov
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;

	if ($layer eq 'WindowsDoorsHoles') {
		return $self->povHoles($povray);
	} elsif ($layer eq 'WindowsDoors') {
		return $povray->meshReference($self);
	} else {
		return '';
	}
}

sub povHoles
{
	my $self = shift;
	my $povray = shift;

	# Load window or door model
	my $model = $povray->{downloader}->getMeshData($self->{id});

	# Find bounding box
	my @vertices = @{$model->{vertices}};
	my ($x1, $y1, $z1, $x2, $y2, $z2);
	while (@vertices) {
		my $x = shift @vertices;
		my $y = shift @vertices;
		my $z = shift @vertices;
		$x1 = $x if !defined($x1) || $x < $x1;
		$y1 = $y if !defined($y1) || $y < $y1;
		$z1 = $z if !defined($z1) || $z < $z1;
		$x2 = $x if !defined($x2) || $x > $x2;
		$y2 = $y if !defined($y2) || $y > $y2;
		$z2 = $z if !defined($z2) || $z > $z2;
	}

	# Generate box object
	my $result = qq|box{<$x1,$y1,$z1>,<$x2,$y2,$z2>|;
	$result .= $self->povTransform;
	$result .= $self->povTranslate;
	$result .= qq|}\n|;
	return $result;
}

sub materialTransparency
{
	my $self = shift;
	my $modelMat = shift;
	my $overrideMat = shift;
	# Hack. Forced transparency for glass
	return 0.8 if $overrideMat->{name} eq 'color_1';
	return Planner5D::Model::Ns::materialTransparency($modelMat, $overrideMat);
}

sub povTransform
{
	my $self = shift;
	my $result = Planner5D::Model::Ns::povTransform($self);
	# Hack. All doors and windows for some reason are rotated 90 deg
	$result .= qq| rotate<0,0,90>|;
	return $result;
}

1;
