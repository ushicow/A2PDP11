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

#define RCSR 0xc700
#define RBUF 0xc701
#define XCSR 0xc702
#define XBUF 0xc703

int main(void)
{
    unsigned char rdata;
    unsigned char wdata = 0;
    
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
        } else {
            POKE(XCSR, 128);        // xrdy <= 0
        }
    }
    return 0;
}
