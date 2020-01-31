#!/bin/sh
#
# SKR mini E3 V1.2  -  Marlin 2.0  -  firmware build script
#
# Copyright (c) 2019-2020 Pascal de Bruijn
# Amended by Ruairi O'Donnell



VENV_DIR=/c/Users/ruair/.platformio
MARLIN_DIR=/c/exit/doc/BIGTREETECH-SKR-mini-E3-V1.2/Marlin
BRANCH=upstream/dev-2.1.x #upstream/bugfix-2.0.x
BOARD=STM32F103RC_bigtree_512K

${VENV_DIR}/penv/Scripts/python -m venv ${VENV_DIR}
${VENV_DIR}/penv/Scripts/pip install -U platformio --no-cache-dir

git push -f tags
git clone https://github.com/MarlinFirmware/Marlin ${MARLIN_DIR}
cd ${MARLIN_DIR}
git add .
git commit -m "Updates"
#git push -uqf origin origin/${BRANCH}
git status
git checkout -b ${BRANCH}
curl "https://raw.githubusercontent.com/MarlinFirmware/Configurations/master/config/examples/BigTreeTech/SKR%20Mini%20E3%201.2/Configuration.h" --output Configuration.h
curl "https://raw.githubusercontent.com/MarlinFirmware/Configurations/master/config/examples/BigTreeTech/SKR%20Mini%20E3%201.2/Configuration_adv.h"  --output Configuration_adv.h
git -C ${MARLIN_DIR} commit -a -m "base example config"

git push -uq origin origin/${BRANCH}
cd ..

git remote add origin git@github.com:RuairiSpain/Marlin2.git
sed -i "s@\[platformio\]\ncore_dir = @\[platformio\]\ncore_dir = PlatformIO@" ${MARLIN_DIR}/platformio.ini
sed --slient -E '$!N; /^(.*)\n\1$/!P; D' ${MARLIN_DIR}/platformio.ini # remove duplicate lines

if grep -Fqv "default_envs = ${BOARD}" ${MARLIN_DIR}/platformio.ini
then
  sed -i "s@default_envs.*=.*@default_envs = ${BOARD}@" ${MARLIN_DIR}/platformio.ini
fi


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
sed -i "s@.*#define DEFAULT_AXIS_STEPS_PER_UNIT   { 80, 80, 400, 93 }.*@#define DEFAULT_AXIS_STEPS_PER_UNIT   { 80, 80, 400, 105.68 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_MAX_FEEDRATE.*@#define DEFAULT_MAX_FEEDRATE          { 500, 500, 20, 60 }@" ${MARLIN_DIR}/Marlin/Configuration.h


# discovered from BigTreeTech reference firmware sources
sed -i "s@#if HAS_TMC220x && !defined(TARGET_LPC1768) && ENABLED(ENDSTOP_INTERRUPTS_FEATURE)@& \&\& !defined(TARGET_STM32F1)@g" ${MARLIN_DIR}/Marlin/src/inc/SanityCheck.h
sed -i "s@/*#define ENDSTOP_INTERRUPTS_FEATURE@#define ENDSTOP_INTERRUPTS_FEATURE@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@//#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define FAN_SOFT_PWM@#define FAN_SOFT_PWM@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define SOFT_ENDSTOPS_MENU_ITEM@#define SOFT_ENDSTOPS_MENU_ITEM@" ${MARLIN_DIR}/Marlin/Configuration.h


# beware https://github.com/MarlinFirmware/Marlin/pull/16143
sed -i "s@.*#define SD_CHECK_AND_RETRY@#define SD_CHECK_AND_RETRY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h



# save some space, since slicers don"t use it
sed -i "s@.*#define ARC_SUPPORT@//#define ARC_SUPPORT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h



# personal tweaks
sed -i 's@#define STRING_CONFIG_H_AUTHOR .*@#define STRING_CONFIG_H_AUTHOR "Lapido SKR E3"@' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i 's@#define CUSTOM_MACHINE_NAME .*@#define CUSTOM_MACHINE_NAME "Lapido"@' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SHOW_BOOTSCREEN@//#define SHOW_BOOTSCREEN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define SHOW_CUSTOM_BOOTSCREEN@//#define SHOW_CUSTOM_BOOTSCREEN@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define CUSTOM_STATUS_SCREEN_IMAGE@//#define CUSTOM_STATUS_SCREEN_IMAGE@" ${MARLIN_DIR}/Marlin/Configuration.h
#sed -i "s@/.*#define CLASSIC_JERK@#define CLASSIC_JERK@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define LEVEL_BED_CORNERS@#define LEVEL_BED_CORNERS@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define LEVEL_CORNERS_INSET .*@  #define LEVEL_CORNERS_INSET 33@g" ${MARLIN_DIR}/Marlin/Configuration.h

sed -i "s@.*#define JUNCTION_DEVIATION_MM .*@  #define JUNCTION_DEVIATION_MM 0.04@g" ${MARLIN_DIR}/Marlin/Configuration.h

#sed -i "s@.*#define S_CURVE_ACCELERATION@//#define S_CURVE_ACCELERATION@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define LIN_ADVANCE@#define LIN_ADVANCE@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define LIN_ADVANCE_K .*@  #define LIN_ADVANCE_K 0.50@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define MONITOR_DRIVER_STATUS@#define MONITOR_DRIVER_STATUS@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define CANCEL_OBJECTS@#define CANCEL_OBJECTS@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h

sed -i "s@/.*#define Z_MIN_PROBE_REPEATABILITY_TEST@  #define Z_MIN_PROBE_REPEATABILITY_TEST@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define RESTORE_LEVELING_AFTER_G28@  #define RESTORE_LEVELING_AFTER_G28@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define GRID_MAX_POINTS_X 3@  #define GRID_MAX_POINTS_X 5@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define Z_SAFE_HOMING_X_POINT ((X_BED_SIZE) / 2)@  #define Z_SAFE_HOMING_X_POINT ((X_BED_SIZE - 60) / 2)@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define Z_SAFE_HOMING_Y_POINT ((Y_BED_SIZE) / 2)@  #define Z_SAFE_HOMING_Y_POINT ((Y_BED_SIZE - 20) / 2)@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/.*#define NOZZLE_CLEAN_FEATURE@  #define NOZZLE_CLEAN_FEATURE@g" ${MARLIN_DIR}/Marlin/Configuration.h

sed -i "s@.*#define ENDSTOPS_ALWAYS_ON_DEFAULT@#define ENDSTOPS_ALWAYS_ON_DEFAULT@g" ${MARLIN_DIR}/Marlin/Configuration_adv.h

sed -i "s@.*#define INDIVIDUAL_AXIS_HOMING_MENU@#define INDIVIDUAL_AXIS_HOMING_MENU@" ${MARLIN_DIR}/Marlin/Configuration.h

sed -i "s@.*#define SQUARE_WAVE_STEPPING@  //#define SQUARE_WAVE_STEPPING@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define PRINT_PROGRESS_SHOW_DECIMALS@#define PRINT_PROGRESS_SHOW_DECIMALS@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


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



# lcd tweaks
sed -i "s@.*#define DOGM_SD_PERCENT@  #define DOGM_SD_PERCENT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define LCD_SET_PROGRESS_MANUALLY@#define LCD_SET_PROGRESS_MANUALLY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define SHOW_REMAINING_TIME@  #define SHOW_REMAINING_TIME@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define USE_M73_REMAINING_TIME@    #define USE_M73_REMAINING_TIME@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define ROTATE_PROGRESS_DISPLAY@    #define ROTATE_PROGRESS_DISPLAY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/.*#define STATUS_HEAT_PERCENT@#define STATUS_HEAT_PERCENT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


# nozzle parking
sed -i "s@.*#define NOZZLE_PARK_FEATURE@#define NOZZLE_PARK_FEATURE@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define NOZZLE_PARK_POINT .*@  #define NOZZLE_PARK_POINT { 0, (Y_MAX_POS - 10), 20 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i 's@.*#define EVENT_GCODE_SD_STOP .*@  #define EVENT_GCODE_SD_STOP "G1 E-3 F3600\\nG27 P2"@g' ${MARLIN_DIR}/Marlin/Configuration_adv.h



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



# firmware based retraction support (causes problems)
#sed -i "s@.*//#define FWRETRACT@#define FWRETRACT@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define RETRACT_LENGTH .*@  #define RETRACT_LENGTH 6@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
#sed -i "s@.*#define RETRACT_FEEDRATE .*@  #define RETRACT_FEEDRATE 60@" ${MARLIN_DIR}/Marlin/Configuration_adv.h



# filament runout sensor (but disabled by default)
sed -i "s@.*#define FILAMENT_RUNOUT_SENSOR@#define FILAMENT_RUNOUT_SENSOR@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*runout.enabled = true@    runout.enabled = false@g" ${MARLIN_DIR}/Marlin/src/module/configuration_store.cpp



# hot-end pid retuning
sed -i "s@#define DEFAULT_Kp 21.73@#define DEFAULT_Kp 23.24@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_Ki 1.54@#define DEFAULT_Ki 2.03@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define DEFAULT_Kd 76.55@#define DEFAULT_Kd 66.60@" ${MARLIN_DIR}/Marlin/Configuration.h



# make sure bed pid temp remains disabled, to keep compatibility with flex-steel pei
sed -i "s@.*#define PIDTEMPBED@#define PIDTEMPBED@" ${MARLIN_DIR}/Marlin/Configuration.h



# add a little more safety, limits selectable temp to 10 degrees less
sed -i "s@#define BED_MAXTEMP .*@#define BED_MAXTEMP      90@g" ${MARLIN_DIR}/Marlin/Configuration.h



# add a little more safety, limits selectable temp to 15 degrees less
sed -i "s@#define HEATER_0_MAXTEMP 275@#define HEATER_0_MAXTEMP 265@g" ${MARLIN_DIR}/Marlin/Configuration.h



# modernize pla preset
sed -i "s@#define PREHEAT_1_TEMP_HOTEND .*@#define PREHEAT_1_TEMP_HOTEND 215@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_1_TEMP_BED .*@#define PREHEAT_1_TEMP_BED     70@g" ${MARLIN_DIR}/Marlin/Configuration.h



# change abs preset to petg
sed -i 's@#define PREHEAT_2_LABEL .*@#define PREHEAT_2_LABEL       "PETG"@g' ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_2_TEMP_HOTEND .*@#define PREHEAT_2_TEMP_HOTEND 240@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define PREHEAT_2_TEMP_BED .*@#define PREHEAT_2_TEMP_BED     70@g" ${MARLIN_DIR}/Marlin/Configuration.h



# bltouch probe on probe connector
sed -i "s@.*#define MESH_BED_LEVELING@//#define MESH_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define MESH_EDIT_MENU@  //#define MESH_EDIT_MENU@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define BLTOUCH@#define BLTOUCH@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define LCD_BED_LEVELING@#define LCD_BED_LEVELING@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define AUTO_BED_LEVELING_BILINEAR@#define AUTO_BED_LEVELING_BILINEAR@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define GRID_MAX_POINTS_X .*@  #define GRID_MAX_POINTS_X 3@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define NOZZLE_TO_PROBE_OFFSET .*@#define NOZZLE_TO_PROBE_OFFSET { -60, -12, -2.55 }@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@#define XY_PROBE_SPEED .*@#define XY_PROBE_SPEED 6000@" ${MARLIN_DIR}/Marlin/Configuration.h


sed -i "s@/*#define MIN_PROBE_EDGE .*@#define MIN_PROBE_EDGE 60@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define EXTRAPOLATE_BEYOND_GRID@#define EXTRAPOLATE_BEYOND_GRID@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define BABYSTEP_MULTIPLICATOR_Z .*@  #define BABYSTEP_MULTIPLICATOR_Z 8@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@.*#define BABYSTEP_MULTIPLICATOR_XY .*@  #define BABYSTEP_MULTIPLICATOR_XY 5@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define BLTOUCH_DELAY 500@#define BLTOUCH_DELAY 500@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define BABYSTEP_DISPLAY_TOTAL@#define BABYSTEP_DISPLAY_TOTAL@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define BABYSTEP_ZPROBE_OFFSET@#define BABYSTEP_ZPROBE_OFFSET@" ${MARLIN_DIR}/Marlin/Configuration_adv.h
sed -i "s@/*#define BABYSTEP_ZPROBE_GFX_OVERLAY@#define BABYSTEP_ZPROBE_GFX_OVERLAY@" ${MARLIN_DIR}/Marlin/Configuration_adv.h

# bltouch probe as z-endstop on z-endstop connector
sed -i "s@#define Z_MAX_POS .*@#define Z_MAX_POS 235@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define Z_SAFE_HOMING@#define Z_SAFE_HOMING@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@#define Z_MIN_PROBE_USES_Z_MIN_ENDSTOP_PIN@" ${MARLIN_DIR}/Marlin/Configuration.h


sed -i "s@/.*#define SHOW_BOOTSCREEN@#define FILAMENT_UNLOAD_PURGE_FEEDRATE 25@" ${MARLIN_DIR}/Marlin/Configuration.h

# use probe connector as z-endstop connector
sed -i "s@.*#define Z_STOP_PIN.*@#define Z_STOP_PIN         PC14@g" ${MARLIN_DIR}/Marlin/src/pins/stm32/pins_BTT_SKR_MINI_E3.h



# debugging
sed -i "s@/*#define MIN_SOFTWARE_ENDSTOP_Z@//#define MIN_SOFTWARE_ENDSTOP_Z@" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@/*#define DEBUG_LEVELING_FEATURE@#define DEBUG_LEVELING_FEATURE@g" ${MARLIN_DIR}/Marlin/Configuration.h
sed -i "s@.*#define TMC_DEBUG@  #define TMC_DEBUG@" ${MARLIN_DIR}/Marlin/Configuration_adv.h


rm Marlin/.pio/build/${BOARD}/firmware.bin

(cd ${MARLIN_DIR}; ${VENV_DIR}/penv/Scripts/platformio run)

grep 'STRING_DISTRIBUTION_DATE.*"' ${MARLIN_DIR}/Marlin/src/inc/Version.h

ls -lh ${MARLIN_DIR}/.pio/build/*/firmware.bin

cp Marlin/.pio/build/${BOARD}/firmware.bin ./firmware-${BRANCH##*/}.bin

cd ${MARLIN_DIR}
git add .
git commit -m "New code for ${BOARD} with branch ${BRANCH##*/}"
git push -uq origin origin/${BRANCH}
git status
cd ..
git add .
git commit -m "New build for ${BOARD} with branch ${BRANCH##*/}"
git push
git status
