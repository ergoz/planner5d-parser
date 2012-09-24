all: myApartment.png

myApartment.pov: planner2pov.pl myApartment.json povray.ini data/pov/*.pov
	./planner2pov.pl < myApartment.json > myApartment.pov

myApartment.png: myApartment.pov
	povray myApartment.pov
