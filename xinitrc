#!/bin/bash

xrdb -merge ~/.Xresources
urxvtd --quiet --opendisplay --fork
xmodmap ~/.Xmodmap
#exec dbus-launch --exit-with-session i3 
picom -b --config ~/.config/picom/picom.conf 
#exec dbus-launch --exit-with-session /home/rebraws/dwm/dwm-installation/bin/dwm
exec dbus-launch /home/rebraws/dwm/dwm-installation/bin/dwm

