# BigTreeTech SKR-mini-E3 V1.2

Marlin binaries with BLTouch most settings are customizable from the LCD display, you can customize:
X, Y, Z Offsets; steps/mm; bed leveling; Probe Z offset; `M48` probe accuracy; Level corners (paper test); Preheat PLA/PTEG; Velocity; Acceleration; Jerk; TMC driver settings; BLTouch settings menu; K value; Runout sensor. These are enabled: Nozzle Park, Junction deviation, Linear Advance, Trinamic hybrid threshold, SCurve not enabled. You can print from SD card or via Cura/OctoPi/PronterFace.

You can enable/disable the BLTOuch by setting the variable `BLTOUCH=true or BLTOUCH=false`. I use a clone BLTouch called 3DTouch, it has a non-standard wire colours so I've added a diagram for anyone that needs it with my wiring colors. I connect my BLTouch to SKR board using `PROBE` and `SERVO` pins. You can set the PIN in the script, with `$PROBE_PIN`, or comment it out and it will be configured for the z-stop. ![Connect #DTouch to Servo and Probe pins](Wiring_3dtouch_skr_mini_e3_1_2_board.png)  
My BLTouch `XYZ` offsets are setup for the Hydra Fan system https://www.thingiverse.com/thing:4062242, but you can change it in the LCD menus

Before doing a big print, you should clibrate your step/mm and Hotend PID and change them in the menus.

This script is fork of [Pascal's project](https://github.com/pmjdebruijn/BIGTREETECH-SKR-mini-E3-V1.2)

Dependencies:
PlatformIO
Git
Bash shell (Windows can use Git Bash command line)

To run (takes about 5-10 minutes to compile):
./skr_mini_e3_build.sh

Then copy the firmware .bin to your SD card and reboot Ender 3. Reflashing the firmware should take 30 seconds/1 minute.  
Check the SD card, to make sure the firmware.bin is renamed to firmware.cur, if the bin file is still on the SD card then delete it, this will speed up boot time of Ender 3.
