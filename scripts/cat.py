#!/usr/bin/env python

import datetime
import os
from pynput.mouse import Controller
import random
from screeninfo import get_monitors
import time

TIME = int(os.environ.get("TIME"))

end_time = datetime.datetime.now() + datetime.timedelta(minutes=TIME)
width = get_monitors()[0].width
height = get_monitors()[0].height
print("This script will run until {}.".format(end_time.strftime("%Y-%m-%d %H:%M")))
print("Screen size width: {}, height: {}".format(width, height))

while True:
    if datetime.datetime.now() >= end_time:
        break
    mouse = Controller()

    random_width = random.randint(0, width)
    random_height = random.randint(0, height)
    print("Move mouse to x: {}, y: {}".format(random_width, random_height))
    mouse.position = (random_width, random_height)

    random_sleep = random.uniform(0, 2.5)
    print("Wait for {} seconds".format(random_sleep))
    time.sleep(random_sleep)

    print("This script will run until {}.".format(end_time.strftime("%Y-%m-%d %H:%M")))
