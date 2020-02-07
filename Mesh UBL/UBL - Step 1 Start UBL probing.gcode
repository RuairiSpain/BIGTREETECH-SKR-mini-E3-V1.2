; ENABLE UBL MESH
M502; CLear EEPROM
M500; Print EEPROM to terminal
M501 ; Load fresh EEPROM
M140 70; Set bed temperature
M190 S70; Wait for bed temperature
G28             ; Home XYZ.
G29 P1          ; Do automated probing of the bed