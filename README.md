# BigTreeTech SKR-mini-E3 V1.2
Marlin binaries with BLTouch  most settings are customizable from the LCD display, you can customize:
X, Y, Z Offsets; steps/mm; bed leveling; Probe Z offset; M48 probe accuracy; Level corners (paper test); Preheat PLA/PTEG; Velocity; Acceleration; Jerk; TMC driver settings; BLTOuch settings menu; K value; Runout sensor.  These are enabled: Nozzle Park, Junction deviation, Linear Advance, Trinamic hybrid threshold, SCurve not enabled.  You can print from SD card or via Cura/OctoPi/PronterFace.


My XYZ offsets are setup for the Hydra Fan system https://www.thingiverse.com/thing:4062242, but you can change it in the LCD menus

My BLTouch clone (3DTouch is connected to the SKR board using PROBE and SERVO pins, see image: ![Connect #DTouch to Servo and Probe pins](Wiring_3dtouch_skr_mini_e3_1_2_board.png)  

My 3DTouch had a wierd wiring setup,  It was Black, White, Red, Green, Yellow.

Before doing a big print, you should clibrate your step/mm and Hotend PID and change them in the menus.

This script is fork of [Pascal's project](https://github.com/pmjdebruijn/BIGTREETECH-SKR-mini-E3-V1.2)

Dependencies:
PlatformIO
Git
Bash shell (Windows can use Git Bash command line)

To run (takes about 5-10 minutes to compile):
./skr_mini_e3_build.sh

Then copy the firmware .bin to your SD card and reboot Ender 3.  Reflashing the firmware should take 30 seconds/1 minute.  
Check the SD card, to make sure the firmware.bin is renamed to firmware.cur,  if the bin file is still on the SD card then delete it, this will speed up boot time of Ender 3.
