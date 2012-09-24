package Planner5D::Povray;

use strict;
use JSON qw(from_json);
use Planner5D::Storage;
use Planner5D::Downloader;

#
# storage => ... - data storage object
# downloader => ... - data downloader object
#
sub new
{
	my $class = shift;
	my %options = @_;
	$options{storage} ||= Planner5D::Storage->new(%options);
	$options{downloader} ||= Planner5D::Downloader->new(%options);
	my $self = {
		storage => $options{storage},
		downloader => $options{downloader},
	};
	return bless $self, $class;
}

#
# Convert mesh to povray object and store it in the cache (if not cached already).
# Return cached file name.
#
sub getPovMeshPath
{
	my $self = shift;
	my $name = shift;

	my $dirPov = $self->{storage}->{varPath} . '/pov';
	my $pathPov = "$dirPov/mesh-$name.pov";
	unless (-e $pathPov) {
		# Load mesh
		my $data = $self->{downloader}->getMeshData($name);

		# Store mesh POV
		$data = $self->meshPov($name, $data);
		mkdir $dirPov;
		open my $f, '>', $pathPov or die "Could not open $pathPov: $!\n";
		print $f $data;
		close $f;
	}
	return $pathPov;
}

#
# Returns array average
#
sub _avg
{
	my $arr = shift;
	return 0 unless $arr;
	return 0 unless @$arr;
	my $sum = 0;
	for my $val (@$arr) {
		$sum += $val;
	}
	return $sum / @$arr;
}

#
# Converts supplied mesh descriptor object to povray program
#
sub meshPov
{
	my $self = shift;
	my $name = shift;
	my $model = shift;

	#return '' if $self->{id} != 154; # яичница
	#return '' if $self->{id} != 78; # кровать
	#return '' if $self->{id} != 101; # плита
	#return '' if $self->{id} != 242; # камин

	my $result = '';

	# Mesh definition
	$result .= qq|mesh2{\n|;

	# Vertex vectors
	my @vertices = @{$model->{vertices}};
	my $nvertices = int(scalar(@vertices) / 3);
	$result .= qq|vertex_vectors{$nvertices|;
	for my $i (0 .. ($nvertices - 1)) {
		$result .= ',<' . $vertices[$i * 3] . ',' . $vertices[$i * 3 + 1] . ',' . $vertices[$i * 3 + 2] . '>';
	}
	$result .= qq|}\n|;

	# Normal vectors
	my @normals = @{$model->{normals}};
	my $nnormals = int(scalar(@normals) / 3);
	$result .= qq|normal_vectors{$nnormals|;
	for my $i (0 .. ($nnormals - 1)) {
		$result .= ',<' . $normals[$i * 3] . ',' . $normals[$i * 3 + 1] . ',' . $normals[$i * 3 + 2] . '>';
	}
	$result .= qq|}\n|;

	# UV vectors
	my @uvs = @{$model->{uvs}->[0]};
	my $nuvs = int(scalar(@uvs) / 2);
	$result .= qq|uv_vectors{$nuvs|;
	for my $i (0 .. ($nuvs - 1)) {
		$result .= ',<' . $uvs[$i * 2] . ',' . $uvs[$i * 2 + 1] . '>';
	}
	$result .= qq|}\n|;

	# Textures
	my @materials = @{$model->{materials}};
	my $nmaterials = scalar(@materials);
	$result .= qq|texture_list{$nmaterials|;
	for my $j (0 .. $#materials) {
		$result .= qq|,texture{p5d_meshtexture_${name}_$j}|;
	}
	$result .= qq|}\n|;

	# Faces
	my @faces = @{$model->{faces}};
	my $nfaces;
	my $faceIndex = 0;
	my @faceVertices;
	my @faceMaterial;
	my @faceUV;
	my @faceVertexUV;
	my @faceNormal;
	my @faceVertexNormal;
	my @faceColor;
	my @faceVertexColor;

	# Parse compressed face stream
	while (@faces) {
		my $type = shift @faces;
		my $isQuad = $type & 1;
		my $hasMaterial = $type & 2;
		my $hasFaceUV = $type & 4;
		my $hasFaceVertexUV = $type & 8;
		my $hasFaceNormal = $type & 16;
		my $hasFaceVertexNormal = $type & 32;
		my $hasFaceColor = $type & 64;
		my $hasFaceVertexColor = $type & 128;

		# Vertices
		my @face;
		push @face, shift @faces;
		push @face, shift @faces;
		push @face, shift @faces;
		push @face, shift @faces if $isQuad;
		$faceVertices[$faceIndex] = \@face;

		# Material
		if ($hasMaterial) {
			$faceMaterial[$faceIndex] = shift @faces;
		}

		# Face UV
		if ($hasFaceUV) {
			my $layerNo = 0;
			for my $layer (@{$model->{uvs}}) {
				my $uvIndex = shift @faces;
				$faceUV[$faceIndex]->[$layerNo] = $uvIndex;
				$layerNo++;
			}
		}

		# Face vertex UV
		if ($hasFaceVertexUV) {
			my $layerNo = 0;
			for my $layer (@{$model->{uvs}}) {
				my @indices;
				for my $f (@face) {
					push @indices, shift @faces;
				}
				$faceVertexUV[$faceIndex]->[$layerNo] = \@indices;
				$layerNo++;
			}
		}

		# Face normal
		if ($hasFaceNormal) {
			$faceNormal[$faceIndex] = shift @faces;
		}

		# Face vertex normal
		if ($hasFaceVertexNormal) {
			my @indices;
			for my $f (@face) {
				push @indices, shift @faces;
			}
			$faceVertexNormal[$faceIndex] = \@indices;
		}

		# Face color
		if ($hasFaceColor) {
			$faceColor[$faceIndex] = shift @faces;
		}

		# Face vertex color
		if ($hasFaceColor) {
			my @indices;
			for my $f (@face) {
				push @indices, shift @faces;
			}
			$faceVertexColor[$faceIndex] = \@indices;
		}

		$faceIndex++;
		$nfaces++;
		$nfaces++ if scalar(@face) == 4;
	}

	$result .= qq|face_indices { $nfaces|;
	for (my $i = 0; $i < $faceIndex; $i++) {
		my $vert = $faceVertices[$i];
		my $mat = $faceMaterial[$i];
		$result .= ',<' . $vert->[0] . ',' . $vert->[1] . ',' . $vert->[2] . '>';
		if (defined($mat)) {
			$result .= qq|, $mat, $mat, $mat|;
		}
		if (@$vert == 4) {
			$result .= ',<' . $vert->[0] . ',' . $vert->[2] . ',' . $vert->[3] . '>';
			if (defined($mat)) {
				$result .= qq|, $mat, $mat, $mat|;
			}
		}
	}
	$result .= qq| }\n|;

	# UV indices
	$result .= qq|uv_indices { $nfaces|;
	for (my $i = 0; $i < $faceIndex; $i++) {
		my $vert = $faceVertices[$i];
		if (defined(my $idx = $faceVertexUV[$i]->[0])) {
			$result .= ',<' . $idx->[0] . ',' . $idx->[1] . ',' . $idx->[2] . '>';
			if (@$vert == 4) {
				$result .= ',<' . $idx->[0] . ',' . $idx->[2] . ',' . $idx->[3] . '>';
			}
		} elsif (defined(my $idx = $faceUV[$i]->[0])) {
			$result .= ',<' . $idx . ',' . $idx . ',' . $idx . '>';
			if (@$vert == 4) {
				$result .= ',<' . $idx . ',' . $idx . ',' . $idx . '>';
			}
		} else {
			$result .= ',<0,0,0>';
			if (@$vert == 4) {
				$result .= ',<0,0,0>';
			}
		}
	}
	$result .= qq|}\n|;

	# Normal indices
	$result .= qq|normal_indices{$nfaces|;
	for (my $i = 0; $i < $faceIndex; $i++) {
		my $vert = $faceVertices[$i];
		if (defined(my $idx = $faceVertexNormal[$i])) {
			$result .= ',<' . $idx->[0] . ',' . $idx->[1] . ',' . $idx->[2] . '>';
			if (@$vert == 4) {
				$result .= ',<' . $idx->[0] . ',' . $idx->[2] . ',' . $idx->[3] . '>';
			}
		} elsif (defined(my $idx = $faceNormal[$i])) {
			$result .= ',<' . $idx . ',' . $idx . ',' . $idx . '>';
			if (@$vert == 4) {
				$result .= ',<' . $idx . ',' . $idx . ',' . $idx . '>';
			}
		} else {
			$result .= ',<0,0,0>';
			if (@$vert == 4) {
				$result .= ',<0,0,0>';
			}
		}
	}
	$result .= qq|}\n|;
	$result .= qq|scale $model->{scale}\n| if $model->{scale};
	$result .= qq|}\n|;
	return $result;
}

#
# Calculate overall scene bounds
#
sub calcBounds
{
	my $self = shift;
	my $root = shift;
	return if $root->{boundsCalculated};
	my ($x1, $y1, $x2, $y2) = $root->bounds;
	$root->{centerX} = ($x1 + $x2) / 2;
	$root->{centerY} = ($y1 + $y2) / 2;
	$root->{sizeX} = ($x2 - $x1) / 2;
	$root->{sizeY} = ($y2 - $y1) / 2;
	$root->{boundsCalculated} = 1;
}

#
# Povray camera
#
sub povCamera
{
	my $self = shift;
	my $root = shift;
	my $location = shift;
	my $lookAt = shift;
	$self->calcBounds($root);
	$location ||= [0, -$root->{sizeY} * 1, 1000];
	$lookAt ||= [0, 0, 0];
	my $result = '';
	$result .= qq|camera{|;
	$result .= 'location <' .
		($root->{centerX} + $location->[0]) . ',' .
		($root->{centerY} + $location->[1]) . ',' .
		$location->[2] . '> ';
	$result .= qq|direction <0,0,-1> |;
	$result .= qq|up <0,-1,0> |;
	$result .= qq|right <1.3333,0,0> |;
	$result .= 'look_at <' .
		($root->{centerX} + $lookAt->[0]) . ',' .
		($root->{centerY} + $lookAt->[1]) . ',' .
		$lookAt->[2] . '> ';
	$result .= "}\n";
	return $result;
}

#
# Light from observer eyes
#
sub povObserverLight
{
	my $self = shift;
	my $root = shift;
	$self->calcBounds($root);
	return qq|light_source{<$root->{centerX},|. ($root->{centerY} - $root->{sizeY} * 0.5) . qq|,1500> color <1,1,1> shadowless}\n|;
}

#
# Sunset light
#
sub povSunsetLight
{
	my $self = shift;
	my $root = shift;
	return qq|light_source {<150000,100000,150000> color <2, 0.8, 0.5>}\n|;
}

#
# Grass
# 
sub povGrass
{
	my $self = shift;
	my $root = shift;
	$self->calcBounds($root);
	my $result = '';
	$result .= qq|box{|;
	$result .= '<' . ($root->{centerX} - $root->{width}/2) . ',' . ($root->{centerY} - $root->{height}/2) . ',-0.1>,';
	$result .= '<' . ($root->{centerX} + $root->{width}/2) . ',' . ($root->{centerY} + $root->{height}/2) . ',-0.01>';
	my $basePath = $self->{storage}->{basePath};
	$result .= qq|texture{pigment{image_map{jpeg "$basePath/textures/grass_8.jpg" interpolate 2}} finish {diffuse 0.5}}|;
	$result .= "}\n";
}

#
# Generate povray program for given scene tree
#
sub povScene
{
	my $self = shift;
	my $root = shift;
	my $result = '';

	# Definitions
	$result .= $self->povDefWalls($root);
	$result .= $self->povDefWindowsDoors($root);
	$result .= $self->povDefWindowsDoorsHoles($root);
	$result .= $self->povDefFloor($root);
	$result .= $self->povDefCeiling($root);
	$result .= $self->povDefObjects($root);

	# Objects
	$result .= $self->povSceneWallsWithHoles($root);
	$result .= $self->povSceneWindowsDoors($root);
	$result .= $self->povSceneFloor($root);
	$result .= $self->povSceneCeiling($root);
	$result .= $self->povSceneObjects($root);

	return $result;
}

sub povDefWalls
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare Walls=object{union{\n|;
	$result .= $root->povItems($self, 'Walls');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povDefWindowsDoors
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare WindowsDoors=object{union{\n|;
	$result .= $root->povItems($self, 'WindowsDoors');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povDefWindowsDoorsHoles
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare WindowsDoorsHoles=object{union{\n|;
	$result .= $root->povItems($self, 'WindowsDoorsHoles');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povDefFloor
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare Floor=object{union{\n|;
	$result .= $root->povItems($self, 'Floor');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povDefCeiling
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare Ceiling=object{union{\n|;
	$result .= $root->povItems($self, 'Ceiling');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povDefObjects
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|#declare Objects=object{union{\n|;
	$result .= $root->povItems($self, 'Objects');
	$result .= qq|}}\n\n|;
	return $result;
}

sub povSceneWalls
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|object{Walls}\n|;
	return $result;
}

sub povSceneWallsWithHoles
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|difference{object{Walls} object {WindowsDoorsHoles}}\n|;
	return $result;
}

sub povSceneWindowsDoors
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|object{WindowsDoors}\n|;
	return $result;
}

sub povSceneFloor
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|object{Floor}\n|;
	return $result;
}

sub povSceneCeiling
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|object{Ceiling}\n|;
	return $result;
}

sub povSceneObjects
{
	my $self = shift;
	my $root = shift;
	my $result = '';
	$result .= qq|object{Objects}\n|;
	return $result;
}

#
# Generate povray reference to mesh object
#
sub meshReference
{
	my $self = shift;
	my $obj = shift;
	my $result = '';

	# Native model data
	my $model = $self->{downloader}->getMeshData($obj->{id});
	my $modelMaterials = $model->{materials} || [];
	my $overrideMaterials = $obj->{materials} || [];

	# Generate material overrides
	for my $i (0 .. $#$modelMaterials) {
		my $modelMat = $modelMaterials->[$i] || {};
		my $overrideMat = $overrideMaterials->[$i] || {};
		my $transparency = $obj->materialTransparency($modelMat, $overrideMat);
		my $reflection = $obj->materialReflection($modelMat, $overrideMat);
		$result .= qq|#declare p5d_meshtexture_$obj->{id}_$i=texture{|;
		if (($overrideMat->{name} =~ /color/) && (my $color = $overrideMat->{color})) {
			# If material name in the object instance contains word
			# "color" and color specification it has preference.
			my $trans = $transparency ? " transmit $transparency" : '';
			if (my ($r, $g, $b) = ($color =~ /#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/)) {
				$r = hex($r) / 255.0;
				$g = hex($g) / 255.0;
				$b = hex($b) / 255.0;
				$result .= qq|pigment{rgb<$r,$g,$b>$trans}|;
			} elsif (my ($r, $g, $b) = ($color =~ /rgb\s*\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/)) {
				$r = $r / 255.0;
				$g = $g / 255.0;
				$b = $b / 255.0;
				$result .= qq|pigment{rgb<$r,$g,$b>$trans}|;
			} else {
				$result .= qq|pigment{rgb<1,0.3,0.3>}|;
			}
		} elsif (my $tex = $overrideMat->{texture}) {
			# If material in the object instance contains texture
			# definition it has preference.
			$tex = $self->{downloader}->getTexturePath($tex . '.jpg');
			my $trans = $transparency ? " transmit all $transparency" : '';
			$result .= qq|pigment{image_map{jpeg "$tex" interpolate 2$trans}}|;
		} elsif (my $color = $modelMat->{colorDiffuse}) {
			# If object instance does not contain material definition but
			# has color specification, it has preference.
			my $trans = $transparency ? " transmit $transparency" : '';
			$result .= qq|pigment{rgb<$color->[0],$color->[1],$color->[2]>$trans}|;
		} else {
			# If no color specification found object is coloured in blue.
			$result .= qq|pigment{rgb<0.3,0.3,1>}|;
		}
		$result .= qq| finish{diffuse | . _avg($modelMat->{colorDiffuse}) .
			qq| specular | . _avg($modelMat->{colorSpecular}) .
			qq| reflection $reflection}|;
		$result .= qq| rotate<90,0,0> scale 0.2|;
		$result .= "}\n";
	}
	
	# Generate object itself
	my $povMesh = $self->getPovMeshPath($obj->{id});
	$result .= qq|object{#include "$povMesh"|;
	$result .= $obj->povTransform;
	$result .= $obj->povTranslate;
	$result .= "}\n";
	return $result;
}

return 1;
