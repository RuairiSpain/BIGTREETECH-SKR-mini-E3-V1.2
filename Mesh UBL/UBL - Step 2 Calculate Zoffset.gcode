;RESET Z-OFFSET
G28; Home
M503; Get Z-offset from terminal
G1 X110 Y110; roughly center
;Paper test on Nozzle in center position (to calculate Z_offset)
M211 S0; turn off end stop restriction negative Z
G91; Use relative positioning
;--------------------------------
; Put paper under nozzle on bed
; Move nozzle up/down until you get friction on the paper under the nozzle
G1 Z-1.0; Move nozzle down 1mm


;G1 Z-1.0; Move nozzle down 1mm
;G1 Z0.1; Move nozzle up .1mm
;G1 Z-0.05; Move nozzle down 0.5mm
;Keep moving until paper friction
;--------------------------------
;M114; read Z offset (Z -1.25)
;G90; Use absolute positioning
;M851 Z-0.25; Set the Z-Offset to -1.25mm (Update Marlin source code Z-Offset value so it's stored as well just in case you re-flash your ROM)
;M503; Show EEPROM on terminal
;M500; Save EEPROM, no need to re-flash because saved to EEPROM, but a good backup scenario