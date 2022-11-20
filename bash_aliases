
lightsoff(){
    echo 0 | sudo tee /sys/class/leds/dell::kbd_backlight/brightness
    }
lightson(){
    echo 3 | sudo tee /sys/class/leds/dell::kbd_backlight/brightness
    }
