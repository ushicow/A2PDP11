/*
 * main.c
 * a2tape
 *
 * Created by ushicow on 2024/11/12.
 * Copyright (c) 2024 nanja.info All rights reserved.
 *
 */

#include <stdio.h>
#include <conio.h>
#include <peekpoke.h>
#include <stdint.h>

#define RCSR 0xc0f0
#define RBUF 0xc0f1
#define XCSR 0xc0f2
#define XBUF 0xc0f3
#define ERROR 0xc0ff

int PutChar(uint8_t wdata) {
    uint8_t rdata;
    
    POKE(RCSR, 128);            // rrdy <= 1
    while (PEEK(RCSR) < 128);   // rstb == 1
    POKE(RBUF, wdata);
    POKE(RCSR, 0);              // rrdy <= 0
    POKE(XCSR, 128);
    while (PEEK(XCSR) < 128);   // xstb == 1
    POKE(XCSR, 0);
    rdata = PEEK(XBUF);
    if (rdata != wdata) {
        POKE(ERROR, rdata);
        printf("\n%x=%x\n", rdata, wdata);
    }
//    putchar(rdata);
    return (rdata != wdata);
}

int SkipHeader(FILE *tape)
{
    int c;
    
    while ((c = fgetc(tape)) == 0);
    if (c != 1) {   // Start Marker = 1
        puts("Start Marker not found");
        return (-1);
    }
    c = fgetc(tape);
    if (c != 0) {   // Pad = 0
        puts("Illigal Start Maker");
        return (-1);
    }
    return 0;
}

int GetWord(FILE *tape) {
    int c;
    int l;

    c = fgetc(tape);
    if (c == EOF) {
        return (-1);
    } else {
        l = c;
    }
    c = fgetc(tape);
    if (c == EOF) {
        return (-1);
    } else {
        l = l + c * 0x100;
    }
    return l;
}

int PutAddress(uint16_t addr)  {
    int i;
    int rdata;
    char addr_str[] = "000000";
    
    sprintf(addr_str, "%06lo", (long)addr);
    for (i = 0; i < 6; ++i) {
        if (PutChar(addr_str[i])) {
            return (-1);
        };
    }
    PutChar('/');
    for (i = 0; i < 7; ++i) {
        POKE(XCSR, 128);
        while (PEEK(XCSR) < 128);   // xstb == 1
        POKE(XCSR, 0);
        rdata = PEEK(XBUF);
//        putchar(rdata);
    }
    return 0;
}

int PutData(uint16_t data)  {
    int i;
    int rdata;
    char data_str[] = "000000";
    
    sprintf(data_str, "%06lo", (long)data);
    for (i = 0; i < 6; ++i) {
        if (PutChar(data_str[i])) {
            return (-1);
        };
    }
    PutChar(0x0d);   // CR
    for (i = 0; i < 2; ++i) {
        POKE(XCSR, 128);
        while (PEEK(XCSR) < 128);  // xstb == 1
        POKE(XCSR, 0);
        rdata = PEEK(XBUF);
//        putchar(rdata);
    }
    return 0;
}


int LoadTape(void)
{
    unsigned char rdata;
    unsigned char wdata = 0;
    FILE *tape;
    int length;
    int address;
    int c;
    uint16_t data;
    uint8_t sum;
    
    printf("Load Tape\n");
    tape = fopen("A.PTAP", "rb");
    if (tape == 0) {
        puts("File Not Found");
        return 1;
    }
    while (1) {
        if (SkipHeader(tape)) {
            break;
        }
        length = GetWord(tape);
        sum = 1 + length / 0x100 + length % 0x100;
        address = GetWord(tape);
        if (address < 0) {
            break;
        }
        sum += address / 0x100 + address % 0x100;
        printf("A:%06o ", address);
        if ((address % 2) == 1) {
            puts("Odd Address");
            break;
        }
        printf("L:%06o \n", length);
        if (length < 6) {
            break;
        } else if ((length % 2) == 1) {
            puts("Odd length");
        } else if (length == 6) {
            puts("Start");
            break;
        }
        while (length > 6) {
            c = fgetc(tape);
            if (c == EOF) {
                break;
            }
            data = c;
            sum += c;
            --length;
            if (length > 6) {
                c = fgetc(tape);
                if (c == EOF) {
                    break;
                }
                data += c * 0x100;
                sum += c;
                --length;
            }
            if (PutAddress(address)) {
                break;
            }
            if (PutData(data)) {
                break;
            }
            address += 2;
        }
        c = fgetc(tape);
        if (c == EOF) {
            break;
        }
        sum += c;
        if (sum) {
            printf("X:%x ", c);
            printf("S:%x ", sum);
            puts("Check sum error");
            break;
        }
    }
    fclose(tape);
    return 0;
}

int main(void)
{
    uint8_t rdata;
    uint8_t wdata = 0;
    char dummy;
    
    printf("Serial Start\n");
    cursor(1);
    POKE(XCSR, 0);
    while (1) {
        if (PEEK(XCSR) >= 128) {        // xstb == 1
            POKE(XCSR, 0);              // xrdy <= 0
            rdata = PEEK(XBUF);
            putchar(rdata);
        } else if (PEEK(RCSR) >= 128) {
            POKE(RBUF, wdata);
            POKE(RCSR, 0);              // rrdy <= 0
        } else if (kbhit()) {
            wdata = cgetc();
            if (wdata == 24) {          // control-X
                return(0);
            } else if (wdata == 18) {   // control-R
                LoadTape();
            }
            POKE(RCSR, 128);            // rrdy <= 1
        } else {
            POKE(XCSR, 128);            // xrdy <= 1
        }
    }
    return 0;
}
