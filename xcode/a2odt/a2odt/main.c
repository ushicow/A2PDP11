/*
 * main.c
 * a2odt
 *
 * Created by ushicow on 2024/11/24.
 * Copyright (c) 2024 nanja.info All rights reserved.
 *
 */
// TEST18

#include <stdio.h>
#include <conio.h>
#include <peekpoke.h>
#include <stdint.h>

#define SLOT 7
#define RCSR (0xc080 + SLOT * 16)
#define RBUF (0xc081 + SLOT * 16)
#define XCSR (0xc082 + SLOT * 16)
#define XBUF (0xc083 + SLOT * 16)
#define PRS  (0xc084 + SLOT * 16)
#define PRB  (0xc085 + SLOT * 16)

FILE *SetTape(void)
{
    char a[] = "?.PTAP";
    FILE *tape;
    int c = 0;
    
    printf("\nREAD TAPE [A-X] ?");
    a[0] = getchar();
    puts("");
    tape = fopen(a, "rb");
    if (tape) {
        while(fgetc(tape) == 0) {
            putchar('.');
            ++c;
        }
        fseek(tape, 0, SEEK_SET);
        fseek(tape, c, SEEK_SET);
    }
    return tape;
}

int ReadTape(FILE *tape)
{
    int c;
    int ret = 0;
    
    c = fgetc(tape);
    if (c != EOF) {
        POKE(PRS, 128);
        while (PEEK(PRS) < 128) {
            if (kbhit()) {
                cgetc();
                puts("eject tape");
                fclose(tape);
                ret = 1;
                break;
            }
        }
//        printf("%03o\n", c);
        POKE(PRB, c);
        POKE(PRS, 0);
    } else {
        puts("end of tape");
        fclose(tape);
        ret = 1;
    }
    return ret;
}

int main(void)
{
    uint8_t rdata;
    uint8_t wdata = 0;
    FILE *tape = 0;
    int prs_error = 1;
    
    printf("Serial Start\n");
    POKE(XCSR, 0);
    while (1) {
        if (PEEK(XCSR) >= 128) {    // xstb == 1
            POKE(XCSR, 0);          // xrdy <= 0
            rdata = PEEK(XBUF);
            putchar(rdata);
        } else if (PEEK(RCSR) >= 128) { // rstb == 1
            POKE(RBUF, wdata);
            POKE(RCSR, 0);          // rrdy <= 0
        } else if (kbhit()) {
            wdata = cgetc();
            if (wdata == 24) {      // Control-X exit
                return(0);
            } else if (wdata == 18) {
                                    // Control-R read tape
                if ((tape = SetTape()) != 0) {
                    prs_error = 0;
                };
            } else {
                POKE(RCSR, 128);    // rrdy <= 1
            }
        } else {
            POKE(XCSR, 128);        // xrdy <= 1
        }
        if (prs_error == 0) {
            prs_error = ReadTape(tape);
        }
    }
    return 0;
}
