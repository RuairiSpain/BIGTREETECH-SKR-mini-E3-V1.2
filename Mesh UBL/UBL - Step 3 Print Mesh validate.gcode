;Start MESH Validation test print (Pretty matrix with circles)
G28; Home
G26 P10; Do test print with a prime line of 10mm to look for bad mesh coordinates
;--------------------------------
;If mesh is all good
;G29 S1; Save mesh to slot 1
;M500; Save to EEPROM
;--------------------------------
;If a mesh coordinate bad (too high/low)
g28; Home
g29 T; Print mesh to terminal