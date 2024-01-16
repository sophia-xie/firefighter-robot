‘general setup
DEFINE ADC_BITS 8
DEFINE ADC_CLOCK 3
DEFINE ADC_SAMPLEUS 50

TRISA=%11111111
TRISB=%00000000
TRISD=%00000000
portb=%00000000
portd=%00000000

‘variables setup
FW VAR BYTE  ‘front wall sensor
SW VAR BYTE  ‘side wall sensor
V VAR BYTE  ‘front wall sensor, linearized
V2 VAR BYTE  ‘side wall sensor, linearized
FD VAR BYTE  ‘flame detection (IR sensor)
LC VAR BYTE  ‘line count
LAC VAR BYTE  ‘line already counted

‘LCD setup
DEFINE LCD_DREG PORTD
DEFINE LCD_DBIT 4
DEFINE LCD_RSREG PORTD
DEFINE LCD_RSBIT 0
DEFINE LCD_EREG PORTD
DEFINE LCD_EBIT 2
DEFINE LCD_RWREG PORTD
DEFINE LCD_RWBIT 1
DEFINE LCD_BITS 4
DEFINE LCD_LINES 2
DEFINE LCD_COMMANDUS 1500
DEFINE LCD_DATAUS 44

LC = 0  ‘set line count to 0
LAC = 0  ‘set line already counted to 0 (0=FALSE, 1=TRUE)

‘main loop
main:

‘sensor setup
ADCON1=0
ADCIN 0, FW  ‘front wall sensor is on A0
ADCIN 1, SW  ‘side wall sensor is on A1
ADCIN 2, FD  ‘flame sensor is on A2

‘linearizing FW and SW
V = (((6787/(FW-4)))-4)/5
V2 = (((6787/(SW-4)))-4)/5

portb=%00001010  ‘both wheels go forward
LCDOUT $FE, 1, #LC  ‘display line count
LCDOUT $FE, $C0, #LAC  ‘display if line already counted

IF FD < 15 AND V < 20 THEN GOTO fan  ‘turn on fan when both a flame and a front wall are near

IF portc.0=0 THEN GOTO line  ‘if a white line is detected
IF portc.0=1 THEN LAC = 0  ‘if black is detected, line already counted = FALSE

IF V < 13 THEN GOTO rightturn  ‘whenever a wall is detected in front, the bot turns right
IF V2 < 16 THEN GOTO right  ‘if too close to left wall
IF V2 > 16 THEN GOTO left  ‘if too far from left wall

GOTO main
‘end of main loop

right:  ‘jog right
portb=%00001000  ‘left wheel moves forward
LCDOUT $FE, 1, #LC
LCDOUT $FE, $C0, #LAC
PAUSE 100
GOTO main

left:  ‘jog left
portb=%00000010  ‘right wheel moves forward
LCDOUT $FE, 1, #LC
LCDOUT $FE, $C0, #LAC
PAUSE 100
GOTO main

rightturn:  ‘sharp right turn (in a corner)
portb=%00001001  ‘left wheel moves forward, right wheel moves backward
LCDOUT $FE, 1, #LC
LCDOUT $FE, $C0, #LAC
PAUSE 900
GOTO main

line:
IF LAC=0 THEN GOTO countline  ‘if line has not been counted yet
GOTO main  ‘if line has already been counted, go back to main loop

countline:
LC = LC + 1  ‘add one to line count
LAC = 1  ‘line already counted = TRUE
IF LC = 6 THEN GOTO roomfour  ‘if bot crosses a line for the sixth time (exiting room three)
GOTO main

roomfour:  ‘hardcoded values
portb=%00001010  ‘forward
PAUSE 1200
portb=%00000110  ‘sharp turn left
PAUSE 900
portb=%00001010  ‘forward
PAUSE 4250
GOTO main  ‘return to main loop (bot will detect an opening on the left and enter room four)

fan:
portb=%00001010  ‘travel forward for half a second
PAUSE 500
portb=%00100000  ‘turn on fan
PAUSE 15000

‘end of code
