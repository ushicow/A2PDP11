/*
 * main.c
 * a2odt
 *
 * Created by Atsushi Ushiroda on 2024/11/10.
 * Copyright (c) 2024 ___ORGANIZATIONNAME___. All rights reserved.
 *
 */
// TEST17

#include <stdio.h>
#include <conio.h>
#include <peekpoke.h>

#define RCSR 0xc0f0
#define RBUF 0xc0f1
#define XCSR 0xc0f2
#define XBUF 0xc0f3

int main(void)
{
    unsigned char rdata;
    unsigned char wdata = 0;
    char dummy;
    
    printf("Serial Start\n");
    cursor(1);
    POKE(XCSR, 0);
    while (1) {
        if (PEEK(XCSR) >= 128) {    // xstb == 1
            POKE(XCSR, 0);          // xrdy <= 1
            rdata = PEEK(XBUF);
            putchar(rdata);
        } else if (PEEK(RCSR) >= 128) {
            POKE(RBUF, wdata);
            POKE(RCSR, 0);
        } else if (kbhit()) {
            wdata = cgetc();
            POKE(RCSR, 128);
            if (wdata == 3) {   // control-C
                puts("HALT");
                dummy = PEEK(0xC700);
            }
            if (wdata == 24) {  // control-X
                return(0);
            }
        } else {
            POKE(XCSR, 128);        // xrdy <= 0
        }
    }
    return 0;
}
