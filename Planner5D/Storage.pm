package Planner5D::Storage;

use strict;
use File::Basename qw(dirname);

#
# basePath => '....' - path to data subdirectory
#
sub new
{
	my $class = shift;
	my %options = @_;
	$options{basePath} ||= _defaultBasePath();
	$options{varPath} ||= $options{basePath} . '/data';
	my $self = {
		basePath => $options{basePath},
		varPath => $options{varPath},
	};
	return bless $self, $class;
}

sub _defaultBasePath
{
	my ($path) = grep { -r $_ } map { join('/', $_, 'Planner5D/Storage.pm') } @INC;
	return undef unless $path;
	return dirname(dirname($path));
}

1;
