#!/bin/sh
echo "Converting runemage.glade to xml format..."
gtk-builder-convert glade/runemage.glade data/ui/runemage.xml

echo "Converting launcher.glade to xml format..."
gtk-builder-convert glade/launcher.glade data/ui/launcher.xml
