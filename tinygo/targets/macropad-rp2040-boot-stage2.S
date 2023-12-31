// Adafruit MacroPad RP2040 Stage 2 Bootloader

//
// This file defines the parameters specific to the flash-chip found
// on the Adafruit MacroPad RP2040.  The generic implementation is in
// rp2040-boot-stage2.S
//

#define BOARD_PICO_FLASH_SPI_CLKDIV   4
#define BOARD_CMD_READ                0xeb
#define BOARD_QUAD_OK                 1
#define BOARD_QUAD_ENABLE_STATUS_BYTE 2
#define BOARD_QUAD_ENABLE_BIT_MASK    2
#define BOARD_SPLIT_STATUS_WRITE      0
#define BOARD_WAIT_CYCLES             4

#include "rp2040-boot-stage2.S"
