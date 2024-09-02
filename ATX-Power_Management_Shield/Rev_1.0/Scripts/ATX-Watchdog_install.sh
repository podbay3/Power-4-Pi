sudo mkdir /usr/local/bin/ATX-Watchdog
echo 'import RPi.GPIO as GPIO
import os
import sys
import time

GPIO.setmode(GPIO.BCM)

pulseStart = 0.0
SHUTDOWN = 24               #pin 18
REBOOTPULSEMINIMUM = 0.2    #reboot pulse signal should be at least this long
REBOOTPULSEMAXIMUM = 0.6    #reboot pulse signal should be at most this long

print ("\n=====================================\n")
print ("== ATX-PSU_startup: Initializing GPIO")
GPIO.setup(SHUTDOWN, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)

try:

    while True:
        print ("\n== Waiting for shutdown pulse\n")
        GPIO.wait_for_edge(SHUTDOWN, GPIO.RISING)

        print ("\nshutdown pulse received\n")
        pulseValue = GPIO.input(SHUTDOWN)
        pulseStart = time.time()

        pinResult = GPIO.wait_for_edge(SHUTDOWN, GPIO.FALLING, timeout = 600)

        if pinResult == None:
            os.system("sudo poweroff")
            sys.exit()
        elif time.time() - pulseStart >= REBOOTPULSEMINIMUM:
            os.system("sudo reboot")
            sys.exit()

        if GPIO.input(SHUTDOWN):
            GPIO.wait_for_edge(SHUTDOWN, GPIO.FALLING)

except:
    pass
finally:
    GPIO.cleanup()
' > /usr/local/bin/ATX-Watchdog/ATX-Watchdog_startup.py
sudo chmod 755 /usr/local/bin/ATX-Watchdog/ATX-Watchdog_startup.py
sudo echo '[Unit]
Description=Signal the ATX-Watchdog that we are starting up

[Service]
Type=simple
RemainAfterExit=true
Restart=on-failure
ExecStart=/usr/bin/python3 /usr/local/bin/ATX-Watchdog/ATX-Watchdog_startup.py

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/ATX-Watchdog_startup.service
sudo systemctl enable ATX-Watchdog_startup
sudo systemctl start ATX-Watchdog_startup
