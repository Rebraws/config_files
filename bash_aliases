hide(){
        export PS1='\u@\h: '
}


DeathStar(){
    ssh rebraws@168.197.48.7 -p 5731

}

lightsoff(){
    echo 0 | sudo tee /sys/class/leds/dell::kbd_backlight/brightness
    }
lightson(){
    echo 3 | sudo tee /sys/class/leds/dell::kbd_backlight/brightness
    }
