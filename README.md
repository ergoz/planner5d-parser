Planner 5D is a web application for editing floorplans with a very simple and user friendly interface.
It is available at http://planner5d.com/

This project is a perl library indended to download floorplans from Planner5D, parse them and convert to other formats.
At the moment following converters are implemented:

* POV-Ray (http://www.povray.org)

# How to download floorplan

```bash
./fetch.pl <identifier>
```

It will download project with given identifier, parse it and save each project in a separate file: *projectName.json*.

# How to convert project to POV-Ray format

```bash
./planner2pov < projectName.json > projectName.pov
```

This command will parse project, download all needed textures and models and generate ready to render POV file.

# How to render the POV file

```bash
povray projectName.pov
```

After rendering you will get projectName.png.

# How to use library API

To parse a project:

```perl
use Planner5D::Parser;
my $parser = Planner5D::Parser->new;
my $root = $parser->parse_string($data);
```

Root object is a Planner5D::Model::Project. All objects are organized in a tree. To get child items of any parent:

```perl
my @children = $parent->items;
```

Every object has fields matching keys from JSON project description. For example:

```perl
assert($root->{className} eq 'Project');
```

To generate POV-Ray output, create a generator object first:

```perl
my $povray = Planner5D::Povray->new;
```

Then you can call its methods to generate parts of POV-Ray program:

```perl
print $povray->povCamera($root);
print $povray->povObserverLight($root);
print $povray->povSunsetLight($root);
print $povray->povGrass($root);
print $povray->povScene($root);
```

* povCamera - generate camera definition. It receives 2 optional arguments: observer position and look_at position. Vectors are given relative to (0, 0, 0) - center of the project on the ground. Every vector is a array reference: [0, 0, 1500]. Measurement units are centimiters.
* povObserverLight - generate light source in default coordinates of camera.
* povSunsetLight - generate red side light similar to the sunset.
* povGrass - generate grass on the ground level.
* povScene - generate all objects required

Instead of using povScene you can use separate methods for corresponding parts of the scene. First group of methods generates #declare statements to define different object groups:

* povDefWalls - walls definition.
* povDefWindowsDoors - windows and doors definition.
* povDefWindowsDoorsHoles - boxes have to be substracted from walls to make holes for windows and doors.
* povDefFloor - floor definition.
* povDefCeiling - ceiling definition.
* povDefObjects - furniture and accessory objects definition.

Other group of methods intended for generation objects itselves:

* povSceneWalls - wall objects without holes for windows and doors.
* povSceneWallsWithHoles - wall objects with holes.
* povSceneFloor - floor object.
* povSceneCeiling - ceiling object.
* povSceneObjects - furniture and accessory objects.

# Resource cache

All downloaded resources are stored in the local filesystem to avoid excessive load to Planner 5D servers. By default data/ subdirectory of the project is used as storage.

You can change it in Parser constructor:

```perl
my $parser = Planner5D::Parser->new(varPath => "$ENV{HOME}/.planner5d");
```

This directory must exist. All subdirectories are created automatically.

# License

This software is dirstributed under terms of BSD License.
