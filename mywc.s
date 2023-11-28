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


//---------------------------------------------------------------------
