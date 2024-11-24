/*
 * main.c
 * a2odt
 *
 * Created by ushicow on 2024/11/24.
 * Copyright (c) 2024 nanja.info All rights reserved.
 *
 */
// TEST17

#include <stdio.h>
#include <conio.h>
#include <peekpoke.h>
#include <stdint.h>

#define RCSR 0xc0f0
#define RBUF 0xc0f1
#define XCSR 0xc0f2
#define XBUF 0xc0f3

int main(void)
{
    uint8_t rdata;
    uint8_t wdata = 0;
    char dummy;
    
    printf("Serial Start\n");
    cursor(1);
    POKE(XCSR, 0);
    while (1) {
        if (PEEK(XCSR) >= 128) {    // xstb == 1
            POKE(XCSR, 0);          // xrdy <= 0
            rdata = PEEK(XBUF);
            putchar(rdata);
        } else if (PEEK(RCSR) >= 128) {
            POKE(RBUF, wdata);
            POKE(RCSR, 0);          // rrdy <= 0
        } else if (kbhit()) {
            wdata = cgetc();
            if (wdata == 24) {      // control-X
                return(0);
            }
            POKE(RCSR, 128);        // rrdy <= 1
        } else {
            POKE(XCSR, 128);        // xrdy <= 1
        }
    }
    return 0;
}
