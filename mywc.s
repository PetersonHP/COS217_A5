//---------------------------------------------------------------------
// mywc.s
// Author: Hugh Peterson
// Date: 12/5/2023
// Description: Write to stdout counts of how many lines, words, and
//      characters are in stdin. A word is a sequence of non-whitespace
//      characters. Whitespace is defined based on the C isspace()
//      function. Return 0. This is an attempt at a direct translation
//      of mywc.c by Bob Dondero from C to A64 Assembly.
//---------------------------------------------------------------------

        .section .rodata

printFormatStr:
        .string "%7ld %7ld %7ld\n"

//---------------------------------------------------------------------

        .section .data

lLineCount:
        .quad 0
lWordCount:
        .quad 0
lCharCount:
        .quad 0

//---------------------------------------------------------------------

        .section .bss

iChar:
        .skip 4
iInWord:
        .skip 4

//---------------------------------------------------------------------

        .section .text

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main
        
main:   
        
        // prologue
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

scanloop:

        // iChar = getChar();
        bl      getchar
        adr     x1, iChar
        str     w0, [x1]

        // if (iChar == EOF) goto endscanloop;
        ldr     w1, [x1]
        cmp     w1, #-1
        beq     endscanloop

        // lCharCount++;
        adr     x0, lCharCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]

        // if (!isspace(iChar)) goto checkspaceelse;
        adr     x0, iChar
        ldr     w1, [x0]
        mov     w0, w1
        bl      isspace
        cmp     w0, #0
        beq     checkspaceelse

        // if (!iInWord) goto inword;
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, #0
        beq     inword

        // lWordCount++;
        adr     x0, lWordCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]

        // inWord = FALSE;
        adr     x0, iInWord
        mov     w1, #0
        str     w1, [x0]

inword:

        // goto checkspaceendif;
        b       checkspaceendif

checkspaceelse:

        // test print DEBUG
        //adr     x0, testFormatStr
        //adr     x1, iChar
        //ldr     w1, [x1]
        //bl      printf

        // if (iInWord) goto notinword;
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, #1
        beq     notinword

        // inWord = TRUE;
        adr     x0, iInWord
        mov     w1, #1
        str     w1, [x0]

notinword:      

checkspaceendif:

        // if (iChar != '\n') goto newline;
        adr     x0, iChar
        ldr     w1, [x0]
        cmp     w1, #10
        bne     newline

        // lLineCount++;
        adr     x0, lLineCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]

newline:

        // goto scanloop
        b       scanloop
        
endscanloop:

        // if (!iInWord) goto trailingword;
        adr     x0, iInWord
        ldr     w1, [x0]
        cmp     w1, #0
        beq     trailingword

        // lWordCount++;
        adr     x0, lWordCount
        ldr     w1, [x0]
        add     w1, w1, #1
        str     w1, [x0]
        
trailingword:

        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount,
        //      lCharCount);
        adr     x0, printFormatStr
        adr     x1, lLineCount
        ldr     w1, [x1]
        adr     x2, lWordCount
        ldr     w2, [x2]
        adr     x3, lCharCount
        ldr     w3, [x3]
        bl      printf
        
        // epilogue
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret
        
//---------------------------------------------------------------------
