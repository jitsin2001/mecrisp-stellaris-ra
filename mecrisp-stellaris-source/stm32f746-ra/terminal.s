@
@    Mecrisp-Stellaris - A native code Forth implementation for ARM-Cortex M microcontrollers
@    Copyright (C) 2013  Matthias Koch
@
@    This program is free software: you can redistribute it and/or modify
@    it under the terms of the GNU General Public License as published by
@    the Free Software Foundation, either version 3 of the License, or
@    (at your option) any later version.
@
@    This program is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@    GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License
@    along with this program.  If not, see <http://www.gnu.org/licenses/>.
@

@ Terminal interface for stm32f746GDiscovery via debug virtual comport
@ VCP_TX - PA9 USART1 AF7 USART1_TX
@ VCP_RX - PB7 USART1 AF7 USART1_RX


@ Terminalroutinen
@ Terminal code and initialisations.
@ Porting: Rewrite this !

  .equ GPIOA_BASE      ,   0x40020000
  .equ GPIOA_MODER     ,   GPIOA_BASE + 0x00
  .equ GPIOA_OTYPER    ,   GPIOA_BASE + 0x04
  .equ GPIOA_OSPEEDR   ,   GPIOA_BASE + 0x08
  .equ GPIOA_PUPDR     ,   GPIOA_BASE + 0x0C
  .equ GPIOA_IDR       ,   GPIOA_BASE + 0x10
  .equ GPIOA_ODR       ,   GPIOA_BASE + 0x14
  .equ GPIOA_BSRR      ,   GPIOA_BASE + 0x18
  .equ GPIOA_LCKR      ,   GPIOA_BASE + 0x1C
  .equ GPIOA_AFRL      ,   GPIOA_BASE + 0x20
  .equ GPIOA_AFRH      ,   GPIOA_BASE + 0x24

  .equ GPIOB_BASE      ,   0x40020400
  .equ GPIOB_MODER     ,   GPIOB_BASE + 0x00
  .equ GPIOB_OTYPER    ,   GPIOB_BASE + 0x04
  .equ GPIOB_OSPEEDR   ,   GPIOB_BASE + 0x08
  .equ GPIOB_PUPDR     ,   GPIOB_BASE + 0x0C
  .equ GPIOB_IDR       ,   GPIOB_BASE + 0x10
  .equ GPIOB_ODR       ,   GPIOB_BASE + 0x14
  .equ GPIOB_BSRR      ,   GPIOB_BASE + 0x18
  .equ GPIOB_LCKR      ,   GPIOB_BASE + 0x1C
  .equ GPIOB_AFRL      ,   GPIOB_BASE + 0x20
  .equ GPIOB_AFRH      ,   GPIOB_BASE + 0x24

  .equ RCC_BASE        ,   0x40023800
  .equ RCC_AHB1ENR     ,   RCC_BASE + 0x30
  .equ RCC_APB1ENR     ,   RCC_BASE + 0x40

  .equ Terminal_USART_Base, 0x40011000 @ USART 1
  .include "../common/stm-terminal.s"  @ Common STM terminal code for emit, key and key?

@ -----------------------------------------------------------------------------
uart_init: @ ( -- )
@ -----------------------------------------------------------------------------

        @ Enable all GPIO peripheral clocks
        ldr r1, = RCC_AHB1ENR
        movs r0, #0x7FF
        str r0, [r1]

        @ Set PORTA pins in alternate function mode
        ldr r1, = GPIOA_MODER
        ldr r0, [r1]
        and r0, 0xFFF4FFFF      @ Zero the bits 18-19 config for PA9 
        orrs r0, #0x800000      @ AF mode for PA9
        str r0, [r1]

        @ Set PORTB pins in alternate function mode
        ldr r1, = GPIOB_MODER
        ldr r0, [r1]
        and r0, 0xFFFF3FFF      @ Zero the bits 14-15 config for PB7 
        orrs r0, #0x8000        @ AF mode for PB7
        str r0, [r1]

        @ Set alternate function 7 to enable USART1 pins on Port A
        ldr  r1, = GPIOA_AFRH
        and  r0, 0xFFFFFF0F     @ Zero the bits 4-7
        orrs r0, #0x70          @ Alternate function 7 for TX pin of USART1 on PA9
        str  r0, [r1]

------------- TODO: >
        @ Enable the USART2 peripheral clock by setting bit 17
        ldr r1, = RCC_APB1ENR
        ldr r0, = BIT17
        str r0, [r1]

    @ Configure BRR by deviding the bus clock with the baud rate

    ldr r1, =Terminal_USART_BRR
    movs r0, #0x8B  @ 115200 bps / 16 MHz HSI
    str r0, [r1]

    @ Enable the USART, TX, and RX circuit
    ldr r1, =Terminal_USART_CR1
    ldr r0, =BIT13+BIT3+BIT2 @ USART_CR1_UE | USART_CR1_TE | USART_CR1_RE
    str r0, [r1]

        bx lr

  .ltorg @ Hier werden viele spezielle Hardwarestellenkonstanten gebraucht, schreibe sie gleich !
