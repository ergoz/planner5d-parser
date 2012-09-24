package Planner5D::Model::Ns;

use strict;
use base 'Planner5D::Model::Object';

sub pov
{
	my $self = shift;
	my $povray = shift;
	my $layer = shift;

	return '' if $layer ne 'Objects';
	return $povray->meshReference($self);
}

sub povTransform
{
	my $self = shift;
	my $result = '';
	$result .= qq| rotate <90,0,0>|;
	$result .= qq| scale <$self->{sX},$self->{sY},$self->{sZ}>|;
	$result .= qq| scale <-1,1,1>| if $self->{fX};
	$result .= qq| scale <1,-1,1>| unless $self->{fY};
	$result .= qq| rotate <0,0,$self->{a}>|;
	return $result;
}

sub povTranslate
{
	my $self = shift;
	my $result = '';
	$result .= qq| translate <$self->{x},$self->{y},$self->{z}>|;
	return $result;
}

sub materialTransparency
{
	my $self = shift;
	my $modelMat = shift;
	my $overrideMat = shift;

	return $modelMat->{transparent} ? $modelMat->{transparency} : 0;
}

sub materialReflection
{
	my $self = shift;
	my $modelMat = shift;
	my $overrideMat = shift;

	# Hack. Mirror reflection
	if ($self->{id} == 239 && $modelMat->{DbgIndex} == 1) {
		return 0.9;
	}
	if ($self->{id} == 144 && $modelMat->{DbgIndex} == 0) {
		return 0.9;
	}
	return 0;
}

1;
