# Automated build script for Marlin on SKR mini E3 V1.2

Marlin binaries with BLTouch most settings are customizable from the LCD display, you can customize:
X, Y, Z Offsets; steps/mm; bed leveling; Probe Z offset; `M48` probe accuracy; Level corners (paper test); Preheat PLA/PTEG; Velocity; Acceleration; Jerk; TMC driver settings; BLTouch settings menu; K value; Runout sensor. These are enabled: Nozzle Park, Junction deviation, SCurve,Trinamic hybrid threshold.  Note Linear Advance is NOT enabled, because I don't like the grinding noise on the extruder motor when it does retraction. You can print from SD card or via Cura/OctoPi/PronterFace.

# Getting started (takes about 5-10 minutes to compile):

```
1. Edit skr_mini_e3_build.sh, check the commments.  There are step1 to 6 to follow.  Save changes.
2. In the Bash shell or unix command line run the script:
        ./skr_mini_e3_build.sh
3. Copy the firmware .bin to your SD card and reboot Ender 3, rename the file so it it called `firmware.bin`. Reflash the firmware should take 30 seconds/1 minute.  Check the SD card, to make sure the firmware.bin is renamed to firmware.cur, if the bin file is still on the SD card then delete it, this will speed up boot time of Ender 3.
```

#How to customize my setup script?


If you look at the script, I downloadthe BTT configuration sample that is in the Marlin configuration repository and then modify the setting to suit my needs.  I've tried to make it easier for other to modify my script by putting most of the important setting at the top of the file.  

Current revision use BLTouch on the PROBE pinhead (not the Z-STOP) this is configured on this line: `PROBE_PIN="PC14"`.  It uses Unified Bed Leveling (UBL) instead of Bilinear during the M29 command, because I want more contorl of the bed meh with 100 coordinates.  It uses double tap for BLTouch probing for better z-offset values, Enable M26 menu so you can run ABL from display. 

If you use UBL, I recommend that you only run M29 once in a while, every week or month.  The M29 bed leveling take 10-15 minutes to setup.  If you want to run M29 with every print then I recommend changing my script to use Bilinear with: `BED_LEVELING="AUTO_BED_LEVELING_BILINEAR"`, this will do standard bed leveling.

I set my bed size to to 226mmx226mmx226mm, because I use very small clips on my glass bed so the inset is about 4mm in from the edge.  You can change the bed size here: `X_BED_SIZE=226 Y_BED_SIZE=226 Z_MAX_POS=226`.

E-steps is configured on this line: `ESTEPS_XYZE`, by default I changed by Extruder E-steps from 93 to 105.68 because I was under-extruding.  This line lets you change all 4 extruders e-steps: `ESTEPS_XYZE="80, 80, 400, 105.68"`.

I have modify the hotend PID so it heat correctly for my printer, if you've not measured your printers PID then comment out these line: `Kp=23.24 Ki=2.03 Kd=66.60`

For the BLTouch you need to set the offset distance between your nozzle and the pin of the BLTouch.  Because my script needs these values for a few things, I split the offset value and the offset direct (see my `OFFSETS_XYZ="-${OFFSETS_X}, -${OFFSETS_Y}, -${OFFSETS_Z}"` variable to set the direct of the offset: negative means the probe pin is LEFT and FORWARD and a DOWN relative to the nozzle.
```
OFFSETS_X=59
OFFSETS_Y=34
OFFSETS_Z=2.40
OFFSETS_XYZ="-${OFFSETS_X}, -${OFFSETS_Y}, -${OFFSETS_Z}"
```

#  Example Script Changes


```

# Step 1. Configure PlatformIO location, if platdformIO not installed then download and install it
PLATFORMIO_DIR=~/.platformio
if [ -d "$PLATFORMIO_DIR" ]; then
  python -c "$(curl -kfsSL https://raw.githubusercontent.com/platformio/platformio/develop/scripts/get-platformio.py)"
fi
${PLATFORMIO_DIR}/penv/Scripts/platformio --version

# Step 2. Marlin Git Branch, example in comments
SHORT_BRANCH=dev-2.1.x  #2.0.3 #dev-2.1.x #bugfix-2.0.x

# Step 3. Simple configuration tweaks
#Tweak e-steps for steppers X, Y, Z and E
ESTEPS_XYZE="80, 80, 400, 105.68"

#URL to download base configuration to change, script uses Marlin files for BTT SKR Mini E3 1.2 as a starting point
CONFIGURATION_PREFIX=https://raw.githubusercontent.com/MarlinFirmware/Configurations/master/config/examples/
CONFIGURATION_PATH="BigTreeTech/SKR Mini E3 1.2" 

# Step 4 printer size and (optional) Hotend PID  values, comment PID out 3 lines if you want the defaults
X_BED_SIZE=226
Y_BED_SIZE=226
Z_MAX_POS=226

Kp=23.24
Ki=2.03
Kd=66.60

# Step 5. BLtouch enable (ture) disable (false)
PROBE="BLTOUCH" #Options:"PROBE_MANUALLY" 'FIX_MOUNTED_PROBE' 'NOZZLE_AS_PROBE' 'Z_PROBE_SERVO_NR' 'TOUCH_MI_PROBE' 'Z_PROBE_SLED' 'RACK_AND_PINION_PROBE'
#Choose the type of bed leveling system you require
BED_LEVELING="AUTO_BED_LEVELING_UBL" #Options: "AUTO_BED_LEVELING_3POINT" "AUTO_BED_LEVELING_LINEAR" "AUTO_BED_LEVELING_BILINEAR" "AUTO_BED_LEVELING_UBL" "MESH_BED_LEVELING"

# Offset for BLTouch relative to nozzle X, Y, Z.  Negative values left, forward and down
OFFSETS_X=59
OFFSETS_Y=34
OFFSETS_Z=2.0
OFFSETS_XYZ="-${OFFSETS_X}, -${OFFSETS_Y}, -${OFFSETS_Z}"

# Step 6.  BLTouch in using non-standard pin, ie PROBE pin is PC14
# comment out line if using BLTouch in using Z-stop (PC2 pin)
#Only use one of these two settings, comment out the one you don't use
PROBE_PIN="PC14"
#Z_MIN_PROBE_PIN="32"

```

# Screenshot:

![Build Script Code](Code.jpg)

# Dependencies:

Git Bash, which is installed with GIT. The script automatically installs the latest platformIO, if it's not installed.

# More Information

You can enable/disable the BLTouch by setting the variable `BLTOUCH=true or BLTOUCH=false`. I use a clone BLTouch called 3DTouch, it has a non-standard wire colours so I've added a diagram for anyone that needs it with my wiring colors. I connect my BLTouch to SKR board using `PROBE` and `SERVO` pins. You can set the PIN in the script, with `$PROBE_PIN`, or comment it out and it will be configured for the z-stop. ![Connect #DTouch to Servo and Probe pins](Wiring_3dtouch_skr_mini_e3_1_2_board.png)  
You can customize the BLTouch offset by editing `OFFSETS_XYZ="-45, -5, -2"`. My BLTouch `XYZ` offsets are setup for the Hydra Fan system https://www.thingiverse.com/thing:4062242. You can change the offsets in the LCD menus when the firmware is flashed to the printer.

Before doing a big print, you should calibrate your step/mm and hot-end PID and change them in the menus. There are variable in the script to customize the PID, example: `Kp="23.24", Ki="2.03", Kd="66.60"`

This script is fork of [Pascal's project](https://github.com/pmjdebruijn/BIGTREETECH-SKR-mini-E3-V1.2)
