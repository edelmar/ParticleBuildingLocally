# ParticleBuildingLocally
Mac OS X app that provides a GUI for doing local build and flash for your Particle devices, and a serial monitor to view the output from your application.

This Mac OS X program makes local building and flashing code to your Particle devices more user friendly, by providing a simple GUI to carry out those tasks instead of using Terminal commands.

The initial screen allows you to pick the branch (latest or develop) of the Particle firmware that you want to clone, or to skip the cloning, if you already have it on your computer. You also use this screen to set up your folders for the firmware, applications, and the curren app you want to flash. These values are saved between launches of the program. You must create the folders first before using the program. Also, if you wish to clone the firmware again to the same folder, you should delete the existing one in that folder first.

The second screen is used to choose the type of build you want to do, to choose the device, and to choose whether to build only, or build and flash.

On the second screen, if you check the 'Serial' box while your device is in dfu mode, the app will open the serial port, when it comes on line, and pipe the output to the text view. Leave this box unchecked, if you don't have any serial output.
