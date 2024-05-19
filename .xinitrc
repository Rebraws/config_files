#!/bin/bash

xrdb -merge ~/.Xresources
urxvtd --quiet --opendisplay --fork
exec dbus-launch --exit-with-session i3
