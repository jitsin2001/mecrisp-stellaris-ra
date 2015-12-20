\ stm32f746g-disco demo
\ pin allocations
\ B_USER  - PI11 - User button
\ USD_D0  - microsSD card
\ USD_D1  - microsSD card
\ USD_D2  - microsSD card
\ USD_D3  - microsSD card
\ USD_CLK - microSD card clock
\ USD_CMD - microSD
\ USD_DETECT - micro sd-card

\ LCD_BL_CTRL - PK3 display led backlight control 0-off 1-on

\ ***** utility functions ***************
\ ***** bitfield utility functions ******
: cnt0   ( m -- b )                      \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                  \ get bitfield at masked position e.g $1234 v ! $f0 v bits@ $3 = . (-1)
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                  \ set bitfield at position $1234 v ! $5 $f00 v bits! v @ $1534 = . (-1)
   >R dup >R cnt0 lshift                 \ shift value to proper pos
   R@ and                                \ mask out unrelated bits
   R> not R@ @ and                       \ invert bitmask and makout new bits
   or r> ! ;                             \ apply value and store back


\ ***** gpio definitions ****************
$40020000 constant GPIO-BASE
: gpio ( n -- adr )
   $f and #10 lshift GPIO-BASE or 1-foldable ;
$04         constant GPIO_OTYPER
$08         constant GPIO_OSPEEDR
$18         constant GPIO_BSRR
$20         constant GPIO_AFRL
$24         constant GPIO_AFRH

#0  GPIO    constant GPIOA
#1  GPIO    constant GPIOB
#2  GPIO    constant GPIOC
#3  GPIO    constant GPIOD
#4  GPIO    constant GPIOE
#5  GPIO    constant GPIOF
#6  GPIO    constant GPIOG
#7  GPIO    constant GPIOH
#8  GPIO    constant GPIOI
#9  GPIO    constant GPIOJ
#10 GPIO    constant GPIOK


: pin#  ( pin -- nr )                    \ get pin number from pin
   $f and 1-foldable ;
: port-base  ( pin -- adr )              \ get port base from pin
   $f bic 1-foldable ;
: port# ( pin -- n )                     \ return gpio port number A:0 .. K:10
   #10 rshift $f and 1-foldable ;
: mode-mask  ( pin -- m )
   #3 swap pin# 2* lshift 1-foldable ;
: mode-shift ( mode pin -- mode<< )      \ shift mode by pin number * 2 for gpio_moder
   pin# 2* lshift 2-foldable ;
: set-mask! ( v m a -- )
   tuck @ swap bic rot or swap ! ;
: bsrr-on  ( pin -- v )                  \ gpio_bsrr mask pin on
   pin# 1 swap lshift 1-foldable ;
: bsrr-off  ( pin -- v )                 \ gpio_bsrr mask pin off
   pin# #16 + 1 swap lshift 1-foldable ;
: af-mask  ( pin -- mask )               \ alternate function bitmask
   $7 and #2 lshift $f swap lshift 1-foldable ;
: af-reg  ( pin -- adr )                 \ alternate function register address for pin
   dup $8 and /2 swap
   port-base GPIO_AFRL + + 1-foldable ;
: af-shift ( af pin -- af )
   pin# #2 lshift swap lshift 2-foldable ;
: gpio-mode! ( mode pin -- )
   tuck mode-shift swap dup
   mode-mask swap port-base set-mask! ;
: mode-af ( af pin -- )
   #2 over gpio-mode!
   tuck af-shift swap dup af-mask swap
   af-reg set-mask ! ;
   

\ ***** rcc definitions *****************
$40023800      constant RCC_BASE         \ rcc base register
$30 RCC_BASE + constant RCC_AHB1ENR      \ AHB1 peripheral clock register
: rcc-gpio-clk-on  ( n -- )              \ enable single gpio port clock
  1 swap lshift RCC_AHB1ENR bis! ;
$30 RCC_BASE + constant RCC_AHB1ENR      \ AHB1 peripheral clock register
: rcc-gpio-clk-off  ( n -- )             \ enable single gpio port clock
  1 swap lshift RCC_AHB1ENR bic! ;

\ ***** lcd definitions *****************
$40016800        constant LTDC              \ LTDC base
$08 LTDC +       constant LTDC_SSR          \ LTDC Synchronization Size Configuration Register
$FFF #16 lshift  constant LTDC_SSR_HSW      \ Horizontal Synchronization Width  ( pixel-1 )
$7FF             constant LTDC_SSR_VSH      \ Vertical   Synchronization Height ( pixel-1 )
$0C LTDC +       constant LTDC_BPCR         \ Back Porch Configuration Register
$FFF #16 lshift  constant LTDC_BPCR_AHBP    \ HSYNC Width  + HBP - 1
$7FF             constant LTDC_BPCR_AVBP    \ VSYNC Height + VBP - 1
$10 LTDC +       constant LTDC_AWCR         \ Active Width Configuration Register
$FFF #16 lshift  constant LTDC_AWCR_AAW     \ HSYNC width  + HBP  + Active Width  - 1
$7ff             constant LTDC_AWCR_AAH     \ VSYNC Height + BVBP + Active Height - 1
$14 LTDC +       constant LTDC_TWCR         \ Total Width Configuration Register
$fff #16 lshift  constant LTDC_TWCR_TOTALW  \ HSYNC Width + HBP  + Active Width  + HFP - 1
$7ff             constant LTDC_TWCR_TOTALH  \ VSYNC Height+ BVBP + Active Height + VFP - 1
$18 LTDC +       constant LTDC_GCR          \ Global Control Register
1  #31 lshift    constant LTDC_GCR_HSPOL    \ Horizontal Synchronization Polarity 0:active low 1: active high
1  #30 lshift    constant LTDC_GCR_VSPOL    \ Vertical Synchronization Polarity 0:active low 1:active high
1  #29 lshift    constant LTDC_GCR_DEPOL    \ Not Data Enable Polarity 0:active low 1:active high
1  #28 lshift    constant LTDC_GCR_PCPOL    \ Pixel Clock Polarity 0:nomal 1:inverted
1  #16 lshift    constant LTDC_GCR_DEN      \ dither enable
$7 #12 lshift    constant LTDC_GCR_DRW      \ Dither Red Width
$7  #8 lshift    constant LTDC_GCR_DGW      \ Dither Green Width
$7  #4 lshift    constant LTDC_GCR_DBW      \ Dither Blue Width
$1               constant LTDC_GCR_LTDCEN   \ LCD-TFT controller enable bit
$24 LTDC +       constant LTDC_SRCR         \ Shadow Reload Configuration Register
1 1 lshift       constant LTDC_SRCR_VBR     \ Vertical Blanking Reload
1                constant LTDC_SRCR_IMR     \ Immediate Reload
$2C LTDC +       constant LTDC_BCCR         \ Background Color Configuration Register RGB888
$FF #16 lshift   constant LTDC_BCCR_BCRED   \ Background Color Red
$FF  #8 lshift   constant LTDC_BCCR_BCGREEN \ Background Color Green
$FF              constant LTDC_BCCR_BCBLUE  \ Background Color Blue
$34 LTDC +       constant LTDC_IER          \ Interrupt Enable Register
#1 #3 lshift     constant LTDC_IER_RRIE     \ Register Reload interrupt enable
#1 #2 lshift     constant LTDC_IER_TERRIE   \ Transfer Error Interrupt Enable
#1 #1 lshift     constant LTDC_IER_FUIE     \ FIFO Underrun Interrupt Enable
#1               constant LTDC_IER_LIE      \ Line Interrupt Enable
$38 LTDC +       constant LTDC_ISR          \ Interrupt Status Register
#1 #3 lshift     constant LTDC_ISR_RRIF     \ Register Reload interrupt flag
#1 #2 lshift     constant LTDC_ISR_TERRIF   \ Transfer Error Interrupt flag
#1 #1 lshift     constant LTDC_ISR_FUIF     \ FIFO Underrun Interrupt flag
#1               constant LTDC_ISR_LIF      \ Line Interrupt flag
$3C LTDC +       constant LTDC_ICR          \ Interrupt Clear Register
#1 #3 lshift     constant LTDC_ICR_CRRIF    \ Register Reload interrupt flag
#1 #2 lshift     constant LTDC_ICR_CTERRIF  \ Transfer Error Interrupt flag
#1 #1 lshift     constant LTDC_ICR_CFUIF    \ FIFO Underrun Interrupt flag
#1               constant LTDC_ICR_CLIF     \ Line Interrupt flag
$40 LTDC +       constant LTDC_LIPCR        \ Line Interrupt Position Configuration Register
$7FF             constant LTDC_LIPCR_LIPOS  \ Line Interrupt Position
$44 LTDC +       constant LTDC_CPSR         \ Current Position Status Register
$FFFF #16 lshift constant LTDC_CPSR_CXPOS   \ Current X Position
$FFFF            constant LTDC_CPSR_CYPOS   \ Current Y Position
$48 LTDC +       constant LTDC_CDSR         \ Current Display Status Register
1 3 lshift       constant LTDC_CDSR_HSYNCS  \ Horizontal Synchronization display Status
1 2 lshift       constant LTDC_CDSR_VSYNCS  \ Vertical Synchronization display Status
1 1 lshift       constant LTDC_CDSR_HDES    \ Horizontal Data Enable display Status
1                constant LTDC_CDSR_VDES    \ Vertical Data Enable display Status
$84 LTDC +       constant LTDC_L1CR         \ Layerx Control Register
1 4 lshift       constant LTDC_LxCR_CLUTEN  \ Color Look-Up Table Enable
1 2 lshift       constant LTDC_LxCR_COLKEN  \ Color Keying Enable
1                constant LTDC_LxCR_LEN     \ layer enable

\ ***** lcd constants *******************
#0 constant LCD-PF-ARGB8888                 \ pixel format argb
#1 constant LCD-PF-RGB888                   \ pixel format rgb
#2 constant LCD-PF-RGB565                   \ pixelformat 16 bit
#3 constant LCD-PF-ARGB1555                 \ pixelformat 16 bit alpha
#4 constant LCD-PF-ARGB4444                 \ pixelformat 4 bit/color + 4 bit alpha
#5 constant LCD-PF-L8                       \ pixelformat luminance 8 bit
#6 constant LCD-PF-AL44                     \ pixelformat 4 bit alpha 4 bit luminance
#7 constant LCD-PF-AL88                     \ pixelformat 8 bit alpha 8 bit luminance

\ ***** lcd gpio ports ******************
#4  GPIOE + constant PE4

#12 GPIOG + constant PG12

#7  GPIOH + constant PH7
#8  GPIOH + constant PH8

#0  GPIOJ + constant PJ0
#1  GPIOJ + constant PJ1
#2  GPIOJ + constant PJ2
#3  GPIOJ + constant PJ3
#4  GPIOJ + constant PJ4
#5  GPIOJ + constant PJ5
#6  GPIOJ + constant PJ6
#7  GPIOJ + constant PJ7
#8  GPIOJ + constant PJ8
#9  GPIOJ + constant PJ9
#10 GPIOJ + constant PJ10
#11 GPIOJ + constant PJ11
#13 GPIOJ + constant PJ13
#14 GPIOJ + constant PJ14
#15 GPIOJ + constant PJ15

#9   GPIOI + constant PI9
#10  GPIOI + constant PI10
#12  GPIOI + constant PI12
#13  GPIOI + constant PI13
#14  GPIOI + constant PI14

#0  GPIOK + constant PK0
#1  GPIOK + constant PK1
#2  GPIOK + constant PK2
#3  GPIOK + constant PK3
#4  GPIOK + constant PK4
#5  GPIOK + constant PK5
#6  GPIOK + constant PK6
#7  GPIOK + constant PK7


PI15 constant LCD_R0                     \ GPIO-AF14
PJ0  constant LCD_R1                     \ GPIO-AF14
PJ1  constant LCD_R2                     \ GPIO-AF14
PJ2  constant LCD_R3                     \ GPIO-AF14
PJ3  constant LCD_R4                     \ GPIO-AF14
PJ4  constant LCD_R5                     \ GPIO-AF14
PJ5  constant LCD_R6                     \ GPIO-AF14
PJ6  constant LCD_R7                     \ GPIO-AF14

PJ7  constant LCD_G0                     \ GPIO-AF14
PJ8  constant LCD_G1                     \ GPIO-AF14
PJ9  constant LCD_G2                     \ GPIO-AF14
PJ10 constant LCD_G3                     \ GPIO-AF14
PJ11 constant LCD_G4                     \ GPIO-AF14
PK0  constant LCD_G5                     \ GPIO-AF14
PK1  constant LCD_G6                     \ GPIO-AF14
PK2  constant LCD_G7                     \ GPIO-AF14

PE4  constant LCD_B0                     \ GPIO-AF14
PJ13 constant LCD_B1                     \ GPIO-AF14
PJ14 constant LCD_B2                     \ GPIO-AF14
PJ15 constant LCD_B3                     \ GPIO-AF14
PG12 constant LCD_B4                     \ GPIO-AF9
PK4  constant LCD_B5                     \ GPIO-AF14
PK5  constant LCD_B6                     \ GPIO-AF14
PK6  constant LCD_B7                     \ GPIO-AF14

PI14 constant LCD_CLK                    \ GPIO-AF14
PK7  constant LCD_DE                     \ GPIO-AF14
PI10 constant LCD_HSYNC                  \ GPIO-AF14
PI9  constant LCD_VSYNC                  \ GPIO-AF14
PI12 constant LCD_DISP
PI13 constant LCD_INT                    \ touch interrupt
PH7  constant LCD_SCL                    \ I2C3_SCL GPIO-AF4 touch i2c
PH8  constant LCD_SDA                    \ I2C3_SCL GPIO-AF4 touch i2c
PK3  constant LCD_BL                     \ lcd back light port

\ ***** LCD Timings *********************
#480 constant RK043FN48H_WIDTH
#272 constant RK043FN48H_HEIGHT
#41  constant RK043FN48H_HSYNC           \ Horizontal synchronization
#13  constant RK043FN48H_HBP             \ Horizontal back porch
#32  constant RK043FN48H_HFP             \ Horizontal front porch
#10  constant RK043FN48H_VSYNC           \ Vertical synchronization
#2   constant RK043FN48H_VBP             \ Vertical back porch
#2   constant RK043FN48H_VFP             \ Vertical front porch


\ ***** lcd functions *******************
: lcd-backlight-init  ( -- )                    \ initialize lcd backlight port
   LCD_BL port# rcc-gpio-clk-on          \ turn on gpio clock
   1 LCD_BL mode-shift
   LCD_BL mode-mask
   LCD_BL port-base set-mask! ;
: lcd-backlight-on  ( -- )                      \ lcd back light on
   LCD_BL bsrr-on LCD_BL port-base GPIO_BSRR + ! ;
: lcd-backlight-off  ( -- )                     \ lcd back light on
   LCD_BL bsrr-off LCD_BL port-base GPIO_BSRR + ! ;
: lcd-clk-init ( -- ) ;
: lcd-gpio-init ( -- ) ;
   #14 LCD_R0 MODE-AF  #14 LCD_R1 MODE-AF  #14 LCD_R2 MODE-AF  #14 LCD_R3 MODE-AF
   #14 LCD_R4 MODE-AF  #14 LCD_R4 MODE-AF  #14 LCD_R6 MODE-AF  #14 LCD_R7 MODE-AF
    
   #14 LCD_G0 MODE-AF  #14 LCD_G1 MODE-AF  #14 LCD_G2 MODE-AF  #14 LCD_G3 MODE-AF
   #14 LCD_G4 MODE-AF  #14 LCD_G5 MODE-AF  #14 LCD_G6 MODE-AF  #14 LCD_G7 MODE-AF
   
   #14 LCD_B0 MODE-AF  #14 LCD_B1 MODE-AF  #14 LCD_B2 MODE-AF  #14 LCD_B3 MODE-AF
    #9 LCD_B4 MODE-AF  #14 LCD_B5 MODE-AF  #14 LCD_B6 MODE-AF  #14 LCD_B7 MODE-AF

   #14 LCD_VSYNC MODE-AF  #14 LCD_HSYNC MODE-AF
   #14 LCD_CLK MODE-AF    #14 LCD_DE    MODE-AF
   01 LCD_DISP gpio-mode! ;
: lcd-disp-on  ( -- )                    \ enable display
   LCD_DISP bsrr-on LCD_DISP port-base GPIO_BSRR + ! ;
: lcd-disp-off  ( -- )                   \ disable display
   LCD_DISP bsrr-off LCD_DISP port-base GPIO_BSRR + ! ;
: lcd-back-color! ( r g b -- )           \ lcd background color
   $ff and swap $ff and #8 lshift or
   swap $ff and #16 lshift or
   LTDC_BCCR @ $ffffff bic or LTDC_BCCR ! ;
: lcd-init-polarity ( -- )               \ initialize polarity
   0 LTDC_GCR_HSPOL LTDC_GCR bits!
   0 LTDC_GCR_VSPOL LTDC_GCR bits!
   0 LTDC_GCR_DEPOL LTDC_GCR bits!
   0 LTDC_GCR_PCPOL LTDC_GCR bits! ;
: lcd-display-init ( -- )                \ set display configuration
   RK043FN48H_HSYNC 1- LTDC_SSR_HSW LTDC_SSR bits!
   RK043FN48H_VSYNC 1- LTDC_SSR_VSH LTDC_SSR bits!
   
   RK043FN48H_HSYNC RK043FN48H_HBP + 1- LTDC_BPCR_AHBP LTDC_BPCR bits!
   RK043FN48H_VSYNC RK043FN48H_VBP + 1- LTDC_BPCR_AVBP LTDC_BPCR bits!
   
   RK043FN48H_WIDTH  RK043FN48H_HSYNC + RK043FN48H_HBP + 1- LTDC_AWCR_AAW LTDC_AWCR bits! 
   RK043FN48H_HEIGHT RK043FN48H_VSYNC + RK043FN48H_VBP + 1- LTDC_AWCR_AAH LTDC_AWCR bits!
   
   RK043FN48H_HEIGHT RK043FN48H_VSYNC +
   RK043FN48H_VBP + RK043FN48H_VFP + 1- LTDC_TWCR_TOTALH LTDC_TWCR bits!
   
   RK043FN48H_WIDTH RK043FN48H_HSYNC +
   RK043FN48H_HBP + RK043FN48H_HFP + 1- LTDC_TWCR_TOTALW LTDC_TWCR bits!
   0 0 0 lcd-back-color!
   lcd-init-polarity
   lcd-backlight-init lcd-backlight-on ;
: layer-base ( l -- offset )                 \ layer offset
   0<> $80 and LTDC + 1-foldable ;
: lcd-layer-on  ( layer -- )                 \ turn on layer
   layer-base $84 + 1 swap bis! ;  
: lcd-layer-off  ( layer -- )                \ turn off layer
   layer-base $84 + 1 swap bic! ;
: lcd-layer-color-key-ena ( l -- )           \ enable color key
   layer-base $84 + 2 swap bis! ;  
: lcd-layer-color-key-dis ( l -- )           \ disable color key
   layer-base $84 + 2 swap bic! ;  
: lcd-layer-color-lookup-table-ena ( l -- )  \ enable color lookup table
   layer-base $84 + $10 swap bis! ;  
: lcd-layer-color-lookup-table-dis ( l -- )  \ disable color lookup table
   layer-base $84 + $10 swap bic! ;  
: lcd-layer-h-start! ( start layer -- )      \ set layer window start position
   layer-base $88 + $FFF swap bits! ;
: lcd-layer-h-end!  ( end layer -- )         \ set layer window end position
   layer-base $88 + $FFF0000 swap bits! ;
: lcd-layer-v-start! ( start layer -- )      \ set layer window vertical start
   layer-base $8C + $7ff swap bits! ; 
: lcd-layer-v-end! ( end layer -- )          \ set layer window vertical end
   layer-base $8C + $7ff0000 swap bits! ; 
: lcd-layer-key-color! ( color layer -- )    \ set layer color keying color
   layer-base $90 + $ffffff swap bits! ; 
: lcd-layer-pixel-format! ( fmt layer -- )   \ set layer pixel format
   layer-base $94 + $7 swap bits! ; 
: lcd-layer-const-alpha! ( alpha layer -- )  \ set layer constant alpha
   layer-base $98 + $FF swap bits! ;
: lcd-layer-default-color! ( c layer -- )    \ set layer default color ( argb8888 )
   layer-base $9C + swap ! ;
: lcd-layer-blend-cfg! ( bf1 bf2 layer -- )  \ set layer blending function
   layer-base $a0 + -rot swap 8 lshift or swap !
: lcd-layer-fb-adr!  ( a layer -- )          \ set layer frame buffer start adr
   layer-base $ac+ swap ! ;
: lcd-layer-fb-pitch! ( pitch layer -- )     \ set layer line distance in byte
   layer-base $B0 + $1FFF0000 swap bits! ;
: lcd-layer-fb-line-length! ( ll layer -- )  \ set layer line length in byte
   layer-base $B0 + $1FFF swap bits! ;
: lcd-layer-num-lines ( lines layer -- )     \ set layer number of lines to buffer
   layer-base $b4 + $7ff swap bits! ;
: lcd-layer-color-map ( c i l -- )           \ set layer color at map index
   layer-base $c4 + -rot
   $ff and #24 lshift swap
   $ffffff and or
   swap ! ;
: layer-0-init ( -- )
   0 lcd-layer-off 0 lcd-layer-color-lookup-table-ena
   0 0 lcd-layer-h-start! RK043FN48H_WIDTH  0 lcd-layer-h-end!
   0 0 lcd-layer-v-start! RK043FN48H_HEIGHT 0 lcd-layer-v-end!
   0 0 lcd-layer-key-color!
   0 0 lcd-layer-pixel-format!
   
   ;