LPT-Application
==========

The application subsystem for LP-Tracker

Created by Wyatt Calandro (Arm1stice)  
Copyright (c) 2017 Wyatt Calandro

License is available in LICENSE

## LP-Tracker Subsystems
LP-Tracker is made up of 3 uderlying subsystems that work together to launch and maintain the application

1. [The Bootloader](https://github.com/LP-Tracker/lpt-bootloader) which launches the appliation and handles crashes and version management
2. [The Updater](https://github.com/LP-Tracker/lpt-updater) which updates application files
3. [The Application](https://github.com/LP-Tracker/lpt-application) which is what the user actually sees

While there are other systems, like Squirrel, that do something similar to the LP-Tracker Bootloader and Updater, I felt is necessary to design my own systems so that I could customize the experience and circumvent some of the issues of code-signing
