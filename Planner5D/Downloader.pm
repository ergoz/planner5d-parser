package Planner5D::Downloader;

use strict;
use LWP::Simple qw(getstore is_error);
use GD;
use JSON qw(from_json);
use Planner5D::Storage;

#
# storage => ... - data storage object
#
sub new
{
	my $class = shift;
	my %options = @_;
	$options{storage} ||= Planner5D::Storage->new(%options);
	my $self = {
		storage => $options{storage},
		debug => $options{debug},
	};
	return bless $self, $class;
}

#
# Download texture and store it in the cache (it not cached already).
# Return cached file name.
#
sub getTexturePath
{
	my $self = shift;
	my $filename = shift;
	my $dir = $self->{storage}->{varPath} . '/textures';
	my $path = "$dir/$filename";
	unless (-e $path) {
		mkdir $dir;
		my $url = "https://planner5d.com/m/t/$filename";
		if ($self->{debug}) {
			print STDERR "Downloading texture $url...\n";
		}
		my $rc = getstore($url, $path);
		if (is_error($rc)) {
			die "Error dowloading texture $url: $rc\n";
		}
	}
	return $path;
}

#
# Download mesh and store it in the cache (it not cached already).
# Return cached file name.
#
sub getMeshPath
{
	my $self = shift;
	my $name = shift;
	my $dir = $self->{storage}->{varPath} . '/meshes';
	my $path = "$dir/$name.json";
	unless (-e $path) {
		mkdir $dir;
		my $pathPng = "$dir/$name.png";
		unless (-e $pathPng) {
			my $url = "https://planner5d.com/m/i/$name.png";
			if ($self->{debug}) {
				print STDERR "Downloading mesh $url...\n";
			}
			my $rc = getstore($url, $pathPng);
			if (is_error($rc)) {
				die "Error dowloading mesh $url: $rc\n";
			}
		}
		my $im = GD::Image->new($pathPng) or die "Could not open PNG file $pathPng\n";
		my $w = $im->width;
		my $h = $im->height;
		my $res = '';
		for (my $y = 0; $y < $h; $y++) {
			for (my $x = 0; $x < $w; $x++) {
				my ($r) = $im->rgb($im->getPixel($x, $y));
				$res .= chr($r);
			}
		}
		open my $f, '>', $path or die "Could not open $path: $!\n";
		print $f $res;
		close $f;
		unlink $pathPng;
	}
	return $path;
}

#
# Load mesh content to memory
#
sub getMeshData
{
	my $self = shift;
	my $name = shift;
	my $path = $self->getMeshPath($name);
	open my $f, '<', $path or die "Could not open $path: $!\n";
	my $data = join '', <$f>;
	close $f;
	eval {
		$data = from_json($data);
	};
	die "Could not parse $path: $@\n" if $@;
	return $data;
}

1;
