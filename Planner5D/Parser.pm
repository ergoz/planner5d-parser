package Planner5D::Parser;

use strict;
use JSON;
use Planner5D::Storage;
use Planner5D::Downloader;

our %classes = (
	Project => 1,
	Floor => 1,
	Room => 1,
	Wall => 1,
	Point => 1,
	Ns => 1,
	Window => 1,
	Door => 1,
);

sub new
{
	my $class = shift;
	my %options = @_;
	$options{storage} ||= Planner5D::Storage->new(%options);
	$options{downloader} ||= Planner5D::Downloader->new(%options);
	my $self = {
		storage => $options{storage},
		downloader => $options{downloader},
		debug => $options{debug},
	};
	return bless $self, $class;
}

#
# Parse entire scene in JSON format
#
sub parse_string
{
	my $self = shift;
	my $data = shift;
	return $self->parse(from_json($data));
}

# 
# Parse entire items description
# Passed object is not preserved
#
sub parse
{
	my $self = shift;
	my $data = shift;

	$self->{unknownClasses} = {};
	return $self->inflate($data);
}

# 
# Convert single item descriptor to Planner5D object
# Passed object is not preserved
#
sub inflate
{
	my $self = shift;
	my $data = shift;

	# Extract class name
	my $className = $data->{className} or return undef;
	unless ($classes{$className}) {
		$self->{unknownClasses}->{$className} = 1;
		return undef;
	}

	# Extract children
	my $items = $data->{items};
	delete $data->{items};

	# Make data an object
	my $class = "Planner5D::Model::$className";
	eval "require $class" or die "Could not import $class: $@";
	bless $data, $class;

	# Attach child items if any
	$data->{items} = [];
	if ($items) {
		for my $item (@$items) {
			my $obj = $self->inflate($item) or next;
			push @{$data->{items}}, $obj;
			$obj->{parent} = $data;
		}
	}

	return $data;
}

#
# Returns list of classes that were not parsed by the parser
#
sub unknownClasses
{
	my $self = shift;
	return keys %{$self->{unknownClasses}};
}

