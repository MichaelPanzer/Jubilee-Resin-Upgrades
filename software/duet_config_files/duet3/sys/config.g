; Jubilee CoreXY ToolChanging Printer - Config File
; This file intended for Duet 3 hardware, main board plus onr expansion boards

; Name and network
; This is configured from the connected Raspberry Pi or here if in stand alone
; mode
;-------------------------------------------------------------------------------
; Networking
;M550 P"Jubilee"           ; Name used in ui and for mDNS  http://Jubilee.local
;M552 P192.168.1.2 S1      ; Use Ethernet with a static IP, 0.0.0.0 for dhcp
;M553 P255.255.255.0       ; Netmask
;M554 192.168.1.1          ; Gateway


; General setup
;-------------------------------------------------------------------------------
M111 S0                    ; Debug off 
M929 P"eventlog.txt" S1    ; Start logging to file eventlog.txt

; General Preferences
M555 P2                    ; Set Marlin-style output
G21                        ; Set dimensions to millimetres
G90                        ; Send absolute coordinates...
M83                        ; ...but relative extruder moves


; Stepper mapping
;-------------------------------------------------------------------------------
; Connected to the MB6HC as the table below.
; Note: first row is numbered left to right and second row right to left
; _________________________________
; | X(Right) | Y(Left)  | U(lock) |
; | Z(Back)  | Z(Right) | Z(Left) |

M584 X0 Y1                ; X and Y for CoreXY
M584 U2                   ; U for toolchanger lock
M584 Z3:4:5               ; Z has three drivers for kinematic bed suspension. 

M569 P0 S0                ; Drive 0 | X stepper
M569 P1 S0                ; Drive 1 | Y Stepper
M906 X{0.9*sqrt(2)*2000}  ; LDO XY 2000mA RMS the TMC5160 driver on duet3
M906 Y{0.9*sqrt(2)*2000}  ; generates a sinusoidal coil current so we can 
                          ; multply by sqrt(2) to get peak used for M906
                          ; Do not exceed 90% without heatsinking the XY 
                          ; steppers.
                                            
M569 P2 S0                  ; Drive 2 | U Tool Changer Lock  670mA
M906 U{0.7*sqrt(2)*670} I60 ; 70% of 670mA RMS idle 60%
                            ; Note that the idle will be shared for all drivers

M569 P3 S0                ; Drive 3 | Front Left Z
M569 P4 S0                ; Drive 4 | Front Right Z
M569 P5 S0                ; Drive 5 | Back Z
M906 Z{0.7*sqrt(2)*1680}  ; 70% of 1680mA RMS

; Expansion 1
; Tool steppers on expansion board (adapt this to your own set up)
M584 E1.0:1.1             ; Extruders for two tools on expansion board address 1
M569 P1.0 S0 D2           ; Drive 6 | Extruder T0 1400mA Spreadcycle Mode
M569 P1.1 S0 D2           ; Drive 7 | Extruder T1 1400mA Spreadcycle Mode
M906 E1400                ; {0.7*sqrt(2)*1400} 70% of 1400mA
                          ; E don't support expressions in 3.2.0-beta4


M569 P3 S0 D2             ; Drive 3 direction | Extruder 0 in Spreadcycle Mode
M569 P4 S0 D2             ; Drive 4 direction | Extruder 1 in Spreadcycle Mode



; Kinematics
;-------------------------------------------------------------------------------
M669 K1                   ; CoreXY mode

; Kinematic bed ball locations.
; Locations are extracted from CAD model assuming lower left build plate corner
; is (0, 0) on a 305x305mm plate.
M671 X297.5:2.5:150 Y313.5:313.5:-16.5 S10 ; Front Left: (297.5, 313.5)
                                           ; Front Right: (2.5, 313.5)
                                           ; Back: (150, -16.5)
                                           ; Up to 10mm correction


; Axis and motor configuration 
;-------------------------------------------------------------------------------

M350 X1 Y1 Z1 U1 E1:1  ; Disable microstepping to simplify calculations
M92 X{1/(0.9*16/180)}  ; step angle * tooth count / 180
M92 Y{1/(0.9*16/180)}  ; The 2mm tooth spacing cancel out with diam to radius
M92 Z{360/0.9/2}       ; 0.9 deg stepper / lead (2mm) of screw 
M92 U{13.76/1.8}       ; gear ration / step angle for tool lock geared motor.
M92 E51.875            ; Extruder - BMG 0.9 deg/step

; Enable microstepping all step per unit will be multiplied by the new step def
M350 X16 Y16 I1        ; 16x microstepping for CoreXY axes. Use interpolation.
M350 U4 I1             ; 4x for toolchanger lock. Use interpolation.
M350 Z16 I1            ; 16x microstepping for Z axes. Use interpolation.
M350 E16:16 I1         ; 16x microstepping for Extruder axes. Use interpolation.

; Speed and acceleration
;-------------------------------------------------------------------------------
M201 X1100 Y1100                        ; Accelerations (mm/s^2)
M201 Z100                               ; LDO ZZZ Acceleration
M201 U800                               ; LDO U Accelerations (mm/s^2)
M201 E1300                              ; Extruder

M203 X18000 Y18000 Z800 E8000 U9000     ; Maximum axis speeds (mm/min)
M566 X500 Y500 Z500 E3000 U50           ; Maximum jerk speeds (mm/min)



; Endstops and probes 
;-------------------------------------------------------------------------------
; Connected to the MB6HC as the table below.
; | U | Z |
; | X |
; | Y |

M574 U1 S1 P"^io0.in"  ; homing position U1 = low-end, type S1 = switch
M574 X1 S1 P"^io1.in"  ; homing position X1 = low-end, type S1 = switch
M574 Y1 S1 P"^io2.in"  ; homing position Y1 = low-end, type S1 = switch

M574 Z0                ; we will use the switch as a Z probe not endstop 
M558 P8 C"io3.in" H3 F360 T6000 ; H = dive height F probe speed T travel speed
G31 K0 X0 Y0 Z-2    ; Set the limit switch position as the  "Control Point."
                    ; Note: the switch free (unclicked) position is 7.2mm,
                    ; but the operating position (clicked) is 6.4 +/- 0.2mm. 
                    ; A 1mm offset (i.e: 7.2-6.2 = 1mm) would be the 
                    ; Z to worst-case free position, but we add an extra 1mm
                    ; such that XY travel moves across the bed when z=0
                    ; do *not* scrape or shear the limit switch.

; Set axis software limits and min/max switch-triggering positions.
; Adjusted such that (0,0) lies at the lower left corner of a 300x300mm square 
; in the 305mmx305mm build plate.
M208 X-13.75:313.75 Y-44:341 Z0:295
M208 U0:200            ; Set Elastic Lock (U axis) max rotation angle



; Heaters and temperature sensors
;-------------------------------------------------------------------------------

; Bed
M308 S0 P"temp0" Y"thermistor" T100000 B3950 A"Bed" ; Keenovo thermistor
M950 H0 C"out0" T0                  ; H = Heater 0
                                    ; C is output for heater itself
                                    ; T = Temperature sensor
M143 H0 S130                        ; Set maximum temperature for bed to 130C    
M307 H0 A589.8 C589.8 D2.2 V24.1 B0 ; Keenovo 750w 230v built in thermistor
                                    ; mandala rose bed
M140 H0                             ; Assign H0 to the bed


; Tools
; Heaters and sensors must be wired to main board for PID tuning (3.2.0-beta4)
M308 S1 P"spi.cs1" Y"rtd-max31865" A"Heater0" ; PT100 on main board
M950 H1 C"0.out3" T1                      ; Heater for extruder out tool 0
; M307 H1 A1252.3 C361.3 D5.3 V24.0 B0    ; from pid tuning without sock
M307 H1 A811.4 C309.4 D4.7 V24.0 B0       ; With sock
M143 H1 S300                              ; Maximum temp for hotend to 300C


; Fans
;-------------------------------------------------------------------------------

M950 F1 C"0.out8"
M106 P1 S255 H1 T45 C"HeatBreakCool0" ; S = Speed of fan Px
                                      ; Hxx = heater for thermo mode
                                      ; T = temps for thermo mode.
M950 F5 C"0.out7"
M106 P5 C"PrintCool0"

; Tool definitions
;-------------------------------------------------------------------------------
M563 P0 S"Tool 0" D0 H1 F5  ; Px = Tool number
                            ; Dx = Drive Number
                            ; H1 = Heater Number
                            ; Fx = Fan number print cooling fan
G10  P0 S0 R0               ; Set tool 0 operating and standby temperatures
                            ; (-273 = "off")
M572 D0 S0.085              ; Set pressure advance

M563 P1 S"Tool 1"


M98  P"/sys/Toffsets.g"     ; Set tool offsets from the bed


M501                        ; Load saved parameters from non-volatile memory

