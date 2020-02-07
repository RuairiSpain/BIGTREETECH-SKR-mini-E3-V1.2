#!/bin/sh
# SKR mini E3 V1.2  -  Marlin 2.0  - automated build script
# Copyright (c) 2019-2020 Pascal de Bruijn
# Modified by RuairiSpain

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
X_BED_SIZE=228
Y_BED_SIZE=228
Z_MAX_POS=220

Kp="23.24"
Ki="2.03"
Kd="66.60"

# Step 5. BLtouch enable (ture) disable (false)
PROBE="BLTOUCH" #Options:"PROBE_MANUALLY" 'FIX_MOUNTED_PROBE' 'NOZZLE_AS_PROBE' 'Z_PROBE_SERVO_NR' 'TOUCH_MI_PROBE' 'Z_PROBE_SLED' 'RACK_AND_PINION_PROBE'
#Choose the type of bed leveling system you require
BED_LEVELING="AUTO_BED_LEVELING_UBL" #Options: "AUTO_BED_LEVELING_3POINT" "AUTO_BED_LEVELING_LINEAR" "AUTO_BED_LEVELING_BILINEAR" "AUTO_BED_LEVELING_UBL" "MESH_BED_LEVELING"
# Offset for BLTouch relative to nozzle X, Y, Z.  Negative values left, forward and down
OFFSETS_XYZ="-59, -34, -2.0"

# Step 6.  BLTouch in using non-standard pin, ie PROBE pin is PC14
# comment out line if using BLTouch in using Z-stop (PC2 pin)
#Only use one of these two settings, comment out the one you don't use
PROBE_PIN="PC14"
#Z_MIN_PROBE_PIN="32"

# MAIN SCRIPT --- ONLY EDIT BELOW HERE IF YOU KNOW WHAT YOU ARE DOING ---
BOARD="STM32F103RC_bigtree_512K" #base board
BRANCH=upstream/${BRANCH} #temporary branch to store forked Marlin code
#Check platformIO and install updates
${PLATFORMIO_DIR}/penv/Scripts/python -m venv ${PLATFORMIO_DIR}
${PLATFORMIO_DIR}/penv/Scripts/pip install -U platformio --no-cache-dir
#URL encode configuration path space -> %20, etc.
CONFIGURATION_PATH=$(python -c $'try: import urllib.request as urllib\nexcept: import urllib\nimport sys\nsys.stdout.write(
urllib.quote(input()))' <<< ${CONFIGURATION_PATH})
#Path for Marlin source code
MARLIN_DIR=./Marlin

echo "Download/Refresh Marlin code in ${MARLIN_DIR}"
# if marlin code is not downloaded then clone the Marlin git repo
if [ ! -d  ${MARLIN_DIR} ]
then
  #clone the Marlin repo and checkout the branch
  git clone -q https://github.com/MarlinFirmware/Marlin ${MARLIN_DIR}
  cd ${MARLIN_DIR}
  git checkout ${SHORT_BRANCH}
else
  #change from the current Marlin branch to the desired build branch
  cd ${MARLIN_DIR}
  git stash
  git fetch --all
  git reset --hard HEAD
  git checkout ${SHORT_BRANCH}
fi



echo "Download Configuration tempaltes"
# download template Configuration.h and Configuration_adv.h files for the example board
cd Marlin
curl -k "${CONFIGURATION_PREFIX}${CONFIGURATION_PATH}/Configuration.h" --output Configuration.h
curl -k "${CONFIGURATION_PREFIX}${CONFIGURATION_PATH}/Configuration_adv.h"  --output Configuration_adv.h

cd ../..

#Start by modifying the PlatformIO config
sed -i "s@core_dir = PlatformIO@@" ${MARLIN_DIR}/platformio.ini
sed -i "s@\[platformio\]@\[platformio\]\ncore_dir = PlatformIO@" ${MARLIN_DIR}/platformio.ini
sed --quiet -E '$!N; /^(.*)\n\1$/!P; D' ${MARLIN_DIR}/platformio.ini > /dev/null 2>&1
#Add our base board to the platformIO config
if grep -Fqv "default_envs = ${BOARD}" ${MARLIN_DIR}/platformio.ini
then
  sed -i "s@default_envs.*=.*@default_envs = ${BOARD}@" ${MARLIN_DIR}/platformio.ini
fi

echo "Setup bed size and PID parameters for hotend"
#Change bed size/ and max print volume
sed -i "s@#define X_BED_SIZE .*@#define X_BED_SIZE ${X_BED_SIZE}@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define Y_BED_SIZE .*@#define Y_BED_SIZE ${X_BED_SIZE}@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define Z_MAX_POS .*@#define Z_MAX_POS ${Z_MAX_POS}@" ${MARLIN_DIR}/Marlin/Configuration.h


#Update hotend PID calibrated defaults
if [ -n "$Kp" ]; then
sed -i "s@#define DEFAULT_Kp 21.73@#define DEFAULT_Kp ${Kp}@" ${MARLIN_DIR}/Marlin/Configuration.h
fi
if [ -n "$Ki" ]; then
sed -i "s@#define DEFAULT_Ki 1.54@#define DEFAULT_Ki ${Ki}@" ${MARLIN_DIR}/Marlin/Configuration.h
fi
if [ -n "$Kd" ]; then
sed -i "s@#define DEFAULT_Kd 76.55@#define DEFAULT_Kd ${Kd}@" ${MARLIN_DIR}/Marlin/Configuration.h
fi

#Turn on firmware retraction, set retraction through menu
sed -i "s@/.*#define FWRETRACT@#define FWRETRACT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h

echo "Enable Reddit tweaks"
#Modify Configuration.h and Configuration_adv.h files
sed -i "s@#define SERIAL_PORT .*@#define SERIAL_PORT 2@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define SERIAL_PORT_2 .*@#define SERIAL_PORT_2 -1@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define BAUDRATE .*@#define BAUDRATE 115200@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@ *#define MOTHERBOARD .*@  #define MOTHERBOARD BOARD_BTT_SKR_MINI_E3_V1_2@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define X_DRIVER_TYPE .*@#define X_DRIVER_TYPE  TMC2209@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define Y_DRIVER_TYPE .*@#define Y_DRIVER_TYPE  TMC2209@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define Z_DRIVER_TYPE .*@#define Z_DRIVER_TYPE  TMC2209@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define E0_DRIVER_TYPE .*@#define E0_DRIVER_TYPE TMC2209@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define CR10_STOCKDISPLAY@#define CR10_STOCKDISPLAY@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SPEAKER@//#define SPEAKER@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define DEFAULT_AXIS_STEPS_PER_UNIT   { 80, 80, 400, 93 }.*@#define DEFAULT_AXIS_STEPS_PER_UNIT   { ${ESTEPS_XYZE} }@" ${MARLIN_DIR}/Marlin/Configuration.h
# discovered from BigTreeTech reference firmware sources
sed -i "s@#if HAS_TMC220x && !defined(TARGET_LPC1768) && ENABLED(ENDSTOP_INTERRUPTS_FEATURE)@& \&\& !defined(TARGET_STM32F1)@g" ${MARLIN_DIR}/Marlin/src/inc/SanityCheck.h
sed -i "s@/*#define ENDSTOP_INTERRUPTS_FEATURE@#define ENDSTOP_INTERRUPTS_FEATURE@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@//#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define FAN_SOFT_PWM@#define FAN_SOFT_PWM@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define SOFT_ENDSTOPS_MENU_ITEM@#define SOFT_ENDSTOPS_MENU_ITEM@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define DISABLE_M503 @#define DISABLE_M503@" ${MARLIN_DIR}/Marlin/Configuration.h
# beware https://github.com/MarlinFirmware/Marlin/pull/16143
sed -i "s@.*#define SD_CHECK_AND_RETRY@#define SD_CHECK_AND_RETRY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
# reduce Hotend fan PWM frequency
sed -i "s@#define SOFT_PWM_SCALE .*@#define SOFT_PWM_SCALE 2@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define SOFT_PWM_DITHER@#define SOFT_PWM_DITHER@" ${MARLIN_DIR}/Marlin/Configuration.h


# save some space, since slicers don"t use it
sed -i "s@.*#define ARC_SUPPORT@//#define ARC_SUPPORT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


echo "Enable personal tweaks"
# personal tweaks
sed -i 's@#define STRING_CONFIG_H_AUTHOR .*@#define STRING_CONFIG_H_AUTHOR "SKR E3"@' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i 's@#define CUSTOM_MACHINE_NAME .*@#define CUSTOM_MACHINE_NAME "Lapido E3"@' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SHOW_BOOTSCREEN@//#define SHOW_BOOTSCREEN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SHOW_CUSTOM_BOOTSCREEN@//#define SHOW_CUSTOM_BOOTSCREEN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define CUSTOM_STATUS_SCREEN_IMAGE@//#define CUSTOM_STATUS_SCREEN_IMAGE@" ${MARLIN_DIR}/Marlin/Configuration.h
#sed -i 's@/.*#define STARTUP_COMMANDS .*@#define STARTUP_COMMANDS "G1 X0 Y0 Z20 F3000"@' ${MARLIN_DIR}/Marlin/Configuration_adv.h

#MARLIN 2.0 Seed features!
echo "Turn off Linear advance (Extruder stepper is skipping with 2.0 speed features)"
#TURN OFF Linear adv because testing shows extruder skipping/skewaking
sed -i "s@#define S_CURVE_ACCELERATION@#define S_CURVE_ACCELERATION@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define LIN_ADVANCE@//#define LIN_ADVANCE@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@#define LIN_ADVANCE_K .*@  #define LIN_ADVANCE_K 0.00@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@#define JUNCTION_DEVIATION_MM .*@  #define JUNCTION_DEVIATION_MM 0.01@g" ${MARLIN_DIR}/Marlin/Configuration.h
#Old Jerk settings
#sed -i "s@/.*#define CLASSIC_JERK@#define CLASSIC_JERK@g" ${MARLIN_DIR}/Marlin/Configuration.h
#sed -i "s@/.*#define LIMITED_JERK_EDITING @#define LIMITED_JERK_EDITING@g" ${MARLIN_DIR}/Marlin/Configuration.h


echo "Set basic settings"
sed -i "s@/*#define MONITOR_DRIVER_STATUS@#define MONITOR_DRIVER_STATUS@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define Z_MIN_PROBE_REPEATABILITY_TEST@  #define Z_MIN_PROBE_REPEATABILITY_TEST@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define RESTORE_LEVELING_AFTER_G28@  #define RESTORE_LEVELING_AFTER_G28@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define Z_SAFE_HOMING_X_POINT ((X_BED_SIZE) / 2)@  #define Z_SAFE_HOMING_X_POINT (X_BED_SIZE / 2)@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define Z_SAFE_HOMING_Y_POINT ((Y_BED_SIZE) / 2)@  #define Z_SAFE_HOMING_Y_POINT (Y_BED_SIZE / 2)@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define Z_HOMING_HEIGHT .*@#define Z_HOMING_HEIGHT 10@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define NOZZLE_CLEAN_FEATURE@  #define NOZZLE_CLEAN_FEATURE@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define ENDSTOPS_ALWAYS_ON_DEFAULT@#define ENDSTOPS_ALWAYS_ON_DEFAULT@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define INDIVIDUAL_AXIS_HOMING_MENU@#define INDIVIDUAL_AXIS_HOMING_MENU@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SQUARE_WAVE_STEPPING@  //#define SQUARE_WAVE_STEPPING@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define PRINT_PROGRESS_SHOW_DECIMALS@#define PRINT_PROGRESS_SHOW_DECIMALS@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define CANCEL_OBJECTS@#define CANCEL_OBJECTS@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h

echo "Set TMC drivers thresholds"
# tmc stepper driver hybrid stealthchop/spreadcycle
sed -i "s@.*#define HYBRID_THRESHOLD@  #define HYBRID_THRESHOLD@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define X_HYBRID_THRESHOLD .*@  #define X_HYBRID_THRESHOLD     150@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define Y_HYBRID_THRESHOLD .*@  #define Y_HYBRID_THRESHOLD     150@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define Z_HYBRID_THRESHOLD .*@  #define Z_HYBRID_THRESHOLD      10@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define E0_HYBRID_THRESHOLD .*@  #define E0_HYBRID_THRESHOLD     60@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h



# sorting (causes problems)
#sed -i "s@.*#define SDCARD_SORT_ALPHA@  #define SDCARD_SORT_ALPHA@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define SDSORT_USES_RAM .*@    #define SDSORT_USES_RAM    true@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define SDSORT_CACHE_NAMES .*@    #define SDSORT_CACHE_NAMES true@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


echo "Enable lcd tweaks"
# lcd tweaks
sed -i "s@.*#define DOGM_SD_PERCENT@  #define DOGM_SD_PERCENT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define LCD_SET_PROGRESS_MANUALLY@#define LCD_SET_PROGRESS_MANUALLY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define SHOW_REMAINING_TIME@  #define SHOW_REMAINING_TIME@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define USE_M73_REMAINING_TIME@    #define USE_M73_REMAINING_TIME@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define ROTATE_PROGRESS_DISPLAY@    #define ROTATE_PROGRESS_DISPLAY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define STATUS_HEAT_PERCENT@#define STATUS_HEAT_PERCENT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h

echo "Enable NOZZLE PARK feature"
# nozzle parking
sed -i "s@.*#define NOZZLE_PARK_FEATURE@#define NOZZLE_PARK_FEATURE@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define NOZZLE_PARK_POINT .*@  #define NOZZLE_PARK_POINT { 0, (Y_MAX_POS - 10), 20 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i 's@.*#define EVENT_GCODE_SD_STOP .*@  #define EVENT_GCODE_SD_STOP "G1 E-3 F3600\\nG27 P2"@g' ${MARLIN_DIR}/Marlin/Configuration_adv.h


echo "Enable filament features and FILAMENT CHANGE"
# advanced pause (for multicolor)
sed -i "s@.*#define EXTRUDE_MAXLENGTH .*@#define EXTRUDE_MAXLENGTH 500@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define ADVANCED_PAUSE_FEATURE@#define ADVANCED_PAUSE_FEATURE@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define PAUSE_PARK_RETRACT_FEEDRATE .*@  #define PAUSE_PARK_RETRACT_FEEDRATE         60@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define PAUSE_PARK_RETRACT_LENGTH .*@  #define PAUSE_PARK_RETRACT_LENGTH            6@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define FILAMENT_CHANGE_UNLOAD_FEEDRATE .*@  #define FILAMENT_CHANGE_UNLOAD_FEEDRATE     20@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define FILAMENT_CHANGE_UNLOAD_LENGTH .*@  #define FILAMENT_CHANGE_UNLOAD_LENGTH      350@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define FILAMENT_CHANGE_FAST_LOAD_FEEDRATE .*@  #define FILAMENT_CHANGE_FAST_LOAD_FEEDRATE  20@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define FILAMENT_CHANGE_FAST_LOAD_LENGTH .*@  #define FILAMENT_CHANGE_FAST_LOAD_LENGTH   350@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define ADVANCED_PAUSE_PURGE_LENGTH .*@  #define ADVANCED_PAUSE_PURGE_LENGTH        100@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define PARK_HEAD_ON_PAUSE@  #define PARK_HEAD_ON_PAUSE@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define FILAMENT_LOAD_UNLOAD_GCODES@  #define FILAMENT_LOAD_UNLOAD_GCODES@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define HOME_BEFORE_FILAMENT_CHANGE@#define HOME_BEFORE_FILAMENT_CHANGE@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


# firmware based retraction support (causes problems)
#sed -i "s@.*//#define FWRETRACT@#define FWRETRACT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define RETRACT_LENGTH .*@  #define RETRACT_LENGTH 6@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define RETRACT_FEEDRATE .*@  #define RETRACT_FEEDRATE 60@" ${MARLIN_DIR}/Marlin/Configuration_adv.h

echo "Turn on RunOut"
# filament runout sensor (but disabled by default)
sed -i "s@.*#define FILAMENT_RUNOUT_SENSOR@#define FILAMENT_RUNOUT_SENSOR@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*runout.enabled = true@    runout.enabled = false@g" ${MARLIN_DIR}/Marlin/src/module/configuration_store.cpp

echo "Change Max temps"
# make sure bed pid temp remains disabled, to keep compatibility with flex-steel pei
sed -i "s@.*#define PIDTEMPBED@#define PIDTEMPBED@" ${MARLIN_DIR}/Marlin/Configuration.h
# add a little more safety, limits selectable temp to 10 degrees less
sed -i "s@#define BED_MAXTEMP .*@#define BED_MAXTEMP      90@g" ${MARLIN_DIR}/Marlin/Configuration.h
# add a little more safety, limits selectable temp to 15 degrees less
sed -i "s@#define HEATER_0_MAXTEMP 275@#define HEATER_0_MAXTEMP 265@g" ${MARLIN_DIR}/Marlin/Configuration.h

echo "Change PLA and PETG presets, remove ABS"
# change pla preset
sed -i "s@#define PREHEAT_1_TEMP_HOTEND .*@#define PREHEAT_1_TEMP_HOTEND 215@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_1_TEMP_BED .*@#define PREHEAT_1_TEMP_BED     70@g" ${MARLIN_DIR}/Marlin/Configuration.h
# change abs preset to petg
sed -i 's@#define PREHEAT_2_LABEL .*@#define PREHEAT_2_LABEL       "PETG"@g' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_2_TEMP_HOTEND .*@#define PREHEAT_2_TEMP_HOTEND 240@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_2_TEMP_BED .*@#define PREHEAT_2_TEMP_BED     70@g" ${MARLIN_DIR}/Marlin/Configuration.h



echo "Probe turn on ${PROBE}"
case "$PROBE" in
'BLTOUCH')
sed -i "s@/*#define BLTOUCH@#define BLTOUCH@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define BLTOUCH_DELAY 500@#define BLTOUCH_DELAY 500@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
;;
'PROBE_MANUALLY')
sed -i "s@/*#define PROBE_MANUALLY@#define PROBE_MANUALLY@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define MANUAL_PROBE_START_Z *.@#define define MANUAL_PROBE_START_Z 0.2@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'FIX_MOUNTED_PROBE')
sed -i "s@/*#define FIX_MOUNTED_PROBE@#define FIX_MOUNTED_PROBE@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'NOZZLE_AS_PROBE')
sed -i "s@/*#define NOZZLE_AS_PROBE@#define NOZZLE_AS_PROBE@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'Z_PROBE_SERVO_NR')
sed -i "s@/*#define Z_PROBE_SERVO_NR .*@#define Z_PROBE_SERVO_NR 0@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define Z_SERVO_ANGLES .*@#define Z_SERVO_ANGLES { 70, 0 } @" ${MARLIN_DIR}/Marlin/Config
;;
'TOUCH_MI_PROBE')
sed -i "s@/*#define TOUCH_MI_PROBE@#define TOUCH_MI_PROBE@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'Z_PROBE_SLED')
sed -i "s@/*#define Z_PROBE_SLED@#define Z_PROBE_SLED@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define SLED_DOCKING_OFFSET .*@/#define SLED_DOCKING_OFFSET 5@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'RACK_AND_PINION_PROBE')
sed -i "s@/*#define RACK_AND_PINION_PROBE@#define RACK_AND_PINION_PROBE@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
esac

echo "BED LEVELING turn on ${BED_LEVELING}"
case "$BED_LEVELING" in
'AUTO_BED_LEVELING_3POINT')
sed -i "s@/*#define AUTO_BED_LEVELING_3POINT@#define AUTO_BED_LEVELING_3POINT@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define MESH_BED_LEVELING@//#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
/usr/bin/startpc
;;
'AUTO_BED_LEVELING_LINEAR')
sed -i "s@/*#define AUTO_BED_LEVELING_LINEAR@#define AUTO_BED_LEVELING_LINEAR@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define MESH_BED_LEVELING@//#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'AUTO_BED_LEVELING_BILINEAR')
sed -i "s@/*#define AUTO_BED_LEVELING_BILINEAR@#define AUTO_BED_LEVELING_BILINEAR@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define MESH_BED_LEVELING@//#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'AUTO_BED_LEVELING_UBL')
sed -i "s@/*#define AUTO_BED_LEVELING_UBL@#define AUTO_BED_LEVELING_UBL@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define MESH_BED_LEVELING@//#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
'MESH_BED_LEVELING')
sed -i "s@/*#define MESH_BED_LEVELING@#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
;;
esac
sed -i "s@#define MIN_PROBE_EDGE .*@#define MIN_PROBE_EDGE 10@" ${MARLIN_DIR}/Marlin/Configuration.h


# Bed leveling settings
echo "BED LEVELING basic updates"
sed -i "s@/*#define LCD_BED_LEVELING@#define LCD_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define MESH_EDIT_MENU@#define MESH_EDIT_MENU@" ${MARLIN_DIR}/Marlin/Configuration.h


#LCD menu for bed leveling with manual paper test
echo "LEVEL CORNERS updates"
sed -i "s@/*#define LEVEL_CENTER_TOO@#define LEVEL_CENTER_TOO\n#define LEVEL_CORNERS_INSET 30@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define LEVEL_CORNERS_INSET .*@#define LEVEL_CORNERS_INSET 28@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define LEVEL_CORNERS_INSET_LFRB { 30, 30, 30, 30 }@#define LEVEL_CORNERS_INSET_LFRB { 28, 28, 28, 28 } @g" ${MARLIN_DIR}/Marlin/Configuration.h


echo "BED LEVELING advanced updates"
if [ "$BED_LEVELING" != "MESH_BED_LEVELING" ]; then #It's not manual mesh bed leveling
  sed -i "s@/*#define NOZZLE_TO_PROBE_OFFSET .*@#define NOZZLE_TO_PROBE_OFFSET { ${OFFSETS_XYZ} }@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@#define GRID_MAX_POINTS_X .*@  #define GRID_MAX_POINTS_X 5@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@/*#define ABL_BILINEAR_SUBDIVISION@#define ABL_BILINEAR_SUBDIVISION@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@/*#define MESH_EDIT_GFX_OVERLAY@#define MESH_EDIT_GFX_OVERLAY@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i 's@/*#define Z_PROBE_END_SCRIPT .*"@#define Z_PROBE_END_SCRIPT "G1 Z10,G1 X0 Y0"@' ${MARLIN_DIR}/Marlin/Configuration.h

  sed -i "s@/*UBL_Z_RAISE_WHEN_OFF_MESH@ UBL_Z_RAISE_WHEN_OFF_MESH@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@#define XY_PROBE_SPEED .*@#define XY_PROBE_SPEED 3000@" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@/*#define MIN_PROBE_EDGE .*@#define MIN_PROBE_EDGE 10@g" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@/*#define EXTRAPOLATE_BEYOND_GRID@#define EXTRAPOLATE_BEYOND_GRID@g" ${MARLIN_DIR}/Marlin/Configuration.h
  sed -i "s@#define BABYSTEP_MULTIPLICATOR_Z .*@  #define BABYSTEP_MULTIPLICATOR_Z 8@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
  sed -i "s@#define BABYSTEP_MULTIPLICATOR_XY .*@  #define BABYSTEP_MULTIPLICATOR_XY 5@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
  sed -i "s@/*#define BABYSTEP_DISPLAY_TOTAL@#define BABYSTEP_DISPLAY_TOTAL@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
  sed -i "s@/*#define BABYSTEP_ZPROBE_OFFSET@#define BABYSTEP_ZPROBE_OFFSET@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
  sed -i "s@/*#define BABYSTEP_ZPROBE_GFX_OVERLAY@#define BABYSTEP_ZPROBE_GFX_OVERLAY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h

  #G26 Mesh validation command setup
  if [ "$BED_LEVELING" = "AUTO_BED_LEVELING_UBL" || "$BED_LEVELING" = "AUTO_BED_LEVELING_BILINEAR"]; then 
    sed -i "s@/*#define G26_MESH_VALIDATION@#define G26_MESH_VALIDATION@" ${MARLIN_DIR}/Marlin/Configuration.h
    sed -i "s@/*#define MESH_TEST_LAYER_HEIGHT .*@#define MESH_TEST_LAYER_HEIGHT 0.3@" ${MARLIN_DIR}/Marlin/Configuration.h
    sed -i "s@/*#define MESH_TEST_HOTEND_TEMP .*@#define MESH_TEST_HOTEND_TEMP 220@" ${MARLIN_DIR}/Marlin/Configuration.h
    sed -i "s@/*#define MESH_TEST_BED_TEMP .*@define MESH_TEST_BED_TEMP 70@" ${MARLIN_DIR}/Marlin/Configuration.h
    sed -i "s@/*#define G26_XY_FEEDRATE .*@define G26_XY_FEEDRATE 20@" ${MARLIN_DIR}/Marlin/Configuration.h
  fi
fi

# bltouch probe as z-endstop on z-endstop connector
sed -i "s@/*#define Z_SAFE_HOMING@#define Z_SAFE_HOMING@" ${MARLIN_DIR}/Marlin/Configuration.h

echo "PROBE PIN updates"
# use probe connector as z-endstop connector
if [ -n "$PROBE_PIN" ]; then
    sed -i "s@.*#define Z_STOP_PIN.*@#define Z_STOP_PIN         ${PROBE_PIN}@g" ${MARLIN_DIR}/Marlin/src/pins/stm32/pins_BTT_SKR_MINI_E3.h
    sed -i "s@/*#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@" ${MARLIN_DIR}/Marlin/Configuration.h
fi
#if [ -n "$Z_MIN_PROBE_PIN" ]; then
#    sed -i "s@/*#define Z_MIN_PROBE_PIN .*@#define Z_MIN_PROBE_PIN $Z_MIN_PROBE_PIN@" ${MARLIN_DIR}/Marlin/Configuration.h
#fi



echo "SPEED AND ACCELERATION features"
#SPEED AND ACCELERATION CHANGES
sed -i "s@#define DEFAULT_MAX_FEEDRATE.*@#define DEFAULT_MAX_FEEDRATE          { 500, 500, 20, 70 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_MAX_ACCELERATION .*@#define DEFAULT_MAX_ACCELERATION      { 2500, 2500, 25000, 5000 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define LIMITED_MAX_ACCEL_EDITING@#define LIMITED_MAX_ACCEL_EDITING@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_ACCELERATION .*@#define DEFAULT_ACCELERATION          2000@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_RETRACT_ACCELERATION .*@#define DEFAULT_RETRACT_ACCELERATION          500@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_TRAVEL_ACCELERATION .*@#define DEFAULT_TRAVEL_ACCELERATION          4000@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define JUNCTION_DEVIATION_MM .*@#define JUNCTION_DEVIATION_MM 0.04@" ${MARLIN_DIR}/Marlin/Configuration.h


#Add PURGE FEED RATE, bugfix for 2.0.2
sed -i "s@/.*#define INCH_MODE_SUPPORT@#define FILAMENT_UNLOAD_PURGE_FEEDRATE 25@" ${MARLIN_DIR}/Marlin/Configuration.h

# debugging
echo "Editing debug features"
sed -i "s@/*#define MIN_SOFTWARE_ENDSTOP_Z@//#define MIN_SOFTWARE_ENDSTOP_Z@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define DEBUG_LEVELING_FEATURE@#define DEBUG_LEVELING_FEATURE@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define TMC_DEBUG@  #define TMC_DEBUG@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


(cd ${MARLIN_DIR}; ${PLATFORMIO_DIR}/penv/Scripts/platformio run)

grep 'STRING_DISTRIBUTION_DATE.*"' ${MARLIN_DIR}/Marlin/src/inc/Version.h

ls -lh ${MARLIN_DIR}/.pio/build/*/firmware.bin
echo "Copying firmare to project root folder"
cp -f Marlin/.pio/build/${BOARD}/firmware.bin ./firmware-${SHORT_BRANCH}.bin

if [ $(whoami) = "ruair" ]; then
  echo "Commit and push changes to Git repos"
  cd ${MARLIN_DIR}
  #git checkout -t backup/${SHORT_BRANCH}
  git pull
  git add .
  git commit -m "New code on ${now} for ${SHORT_BOARD} using branch ${SHORT_BRANCH}"
  git push --set-upstream backup ${SHORT_BRANCH}
  #git status
  cd ..
  #git checkout -t origin/${SHORT_BRANCH}
  git pull
  git add .
  now=$(date  +"%r on %d-%m-%Y")
  git commit -m "Automatic build on ${now} for ${SHORT_BOARD} using branch ${SHORT_BRANCH}"
  git push
  git status

  if [ -d "/d/" ]; then
      echo "Copying to SD card"
      cp -f Marlin/.pio/build/${BOARD}/firmware.bin /d/firmware.bin
      cp -f Marlin/.pio/build/${BOARD}/firmware.bin ./Firmware/firmware-${SHORT_BRANCH}.bin
  fi
fi


