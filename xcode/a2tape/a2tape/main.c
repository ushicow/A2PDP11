/*
 * main.c
 * a2tape
 *
 * Created by Atsushi Ushiroda on 2024/11/12.
 * Copyright (c) 2024 ___ORGANIZATIONNAME___. All rights reserved.
 *
 */


#include <stdio.h>
#include <conio.h>
#include <peekpoke.h>

#define RCSR 0xc0f0
#define RBUF 0xc0f1
#define XCSR 0xc0f2
#define XBUF 0xc0f3

int PutChar(unsigned char wdata) {
    POKE(RCSR, 128);
    while (PEEK(RCSR) >= 128);
    POKE(RBUF, wdata);
    POKE(RCSR, 0);
}

int PutAddress(unsigned int addr)  {
    int i;
    
    for (i = 0; i < 6; ++i) {
        
    }
    PutChar(
}

int PutData(unsigned )
int main(void)
{
    unsigned char rdata;
    unsigned char wdata = 0;
    FILE *tape;
    int c;
    
    printf("Load Tape\n");
    tape = fopen("a.ptap", "rb");
    POKE(XCSR, 128);
        while (1) {
            if (PEEK(XCSR) >= 128) {
                rdata = PEEK(XBUF);
                POKE(XCSR, 0);
                putchar(rdata);
                POKE(XCSR, 128);
            } else if (PEEK(RCSR) >= 128) {
                POKE(RBUF, wdata);
                POKE(RCSR, 0);
            } else {
                wdata = fgetc(tape);
                if wdat!= EOF)
            wdata = cgetc();
            POKE(RCSR, 128);
        }
    }
    return 0;
}
