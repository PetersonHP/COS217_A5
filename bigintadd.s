//---------------------------------------------------------------------
// bigintadd.s
// Author: Hugh Peterson
//---------------------------------------------------------------------

        .section .rodata

zStr:
        .string "Z\n"
nStr:
        .string "N\n"
cStr:
        .string "C\n"
vStr:
        .string "V\n"
        

//---------------------------------------------------------------------

        .section .data

//---------------------------------------------------------------------

        .section .bss

//---------------------------------------------------------------------

        .section .text

        //-------------------------------------------------------------
        // Return the larger of two unsigned longs
        //-------------------------------------------------------------

        // Must be a multiple of 16
        .equ    LARGER_STACK_BYTECOUNT, 32

        // Local variable stack offsets
        .equ    lLarger, 8

        // Parameter stack offsets
        .equ    lLength2, 16
        .equ    lLength1, 24
        
BigInt_larger:
        
        // Prologue
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, lLength1]        
        str     x1, [sp, lLength2]

        // long lLarger;

        // if (lLength1 <= lLength2) goto twoLarger;
        ldr     x0, [sp, lLength1]
        ldr     x1, [sp, lLength2]
        cmp     x0, x1
        ble     twoLarger

        // {

        // lLarger = lLength1;
        ldr     x0, [sp, lLength1]
        add     x1, sp, lLarger
        str     x0, [x1]

        // goto foundLarger;
        b foundLarger

        // }
        
twoLarger:

        // lLarger = lLength2;
        ldr     x0, [sp, lLength2]
        add     x1, sp, lLarger
        str     x0, [x1]

foundLarger:
        
        // Epilog and return lLarger
        ldr     x0, [sp, lLarger]
        ldr     x30, [sp]
        add     sp, sp, LARGER_STACK_BYTECOUNT
        ret

        .size   BigInt_larger, (. - BigInt_larger)

//---------------------------------------------------------------------

        //-------------------------------------------------------------
        // Assign the sum of two addends oAddend1 and oAddend2 to oSum.
        // oSum should be distinct from oAddend1 and oAddend2. Return
        // 0 (FALSE) if an overflow occurred, and 1 (TRUE) otherwise.
        //-------------------------------------------------------------

        // Must be a multiple of 16
        .equ    ADD_STACK_BYTECOUNT, 64

        // Local variable stack offsets
        .equ    ulCarry, 8
        .equ    ulSum, 16
        .equ    lIndex, 24
        .equ    lSumLength, 32

        // Parameter stack offsets
        .equ    oSum, 40
        .equ    oAddend2, 48
        .equ    oAddend1, 56

        // FALSE = 0, TRUE = 1
        .equ    FALSE, 0
        .equ    TRUE, 1

        // sizeof(unsigned long)
        .equ    SIZEOF_ULONG, 8

        // MAX_DIGITS
        .equ    MAX_DIGITS, 32768

        .global BigInt_add
        
BigInt_add:     

        // Prologue
        sub     sp, sp, ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, oAddend1]        
        str     x1, [sp, oAddend2]
        str     x2, [sp, oSum]

        // determine the larger length
        // lSumLength = BigInt_larger(oAddend1->lLength,
        //      oAddend2->lLength);
        ldr     x0, [sp, oAddend1]      // x0 <- first addend address
        ldr     x0, [x0]    // x0 <- lLength for first addend
        ldr     x1, [sp, oAddend2]
        ldr     x1, [x1]
        bl      BigInt_larger  // x0 <- larger length
        add     x1, sp, lSumLength
        str     x0, [x1]

        // Clear oSum's array if necessary.
        // if (oSum->lLength <= lSumLength) goto noClear;
        ldr     x0, [sp, oSum]
        ldr     x0, [x0]
        ldr     x1, [sp, lSumLength]
        cmp     x0, x1
        ble     noClear

        // {

        // memset(oSum->aulDigits, 0, MAX_DIGITS *
        //      sizeof(unsigned long));
        ldr     x0, [sp, oSum]  // x0 <- pointer to oSum
        add     x0, x0, #8    // x0 <- pointer to oSum digits array
        mov     x1, xzr         // w1 <- 0
        mov     x2, SIZEOF_ULONG        // w2 <- sizeof(unsigned long)
        mov     x3, MAX_DIGITS
        mul     x2, x2, x3
        bl      memset
        
        // }        
noClear:

        // ulCarry = 0;
        // ulIndex = 0;
        str     xzr, [sp, ulCarry]
        str     xzr, [sp, lIndex]

startAddLoop:

        // {

        // if (lIndex >= lSumLength) goto endAddLoop;
        ldr     x0, [sp, lIndex]
        ldr     x1, [sp, lSumLength]
        cmp     x0, x1
        bge     endAddLoop

        // ulSum = ulCarry;
        ldr     x0, [sp, ulCarry]
        str     x0, [sp, ulSum]

        // ulCarry = 0;
        add     x0, sp, ulCarry
        str     xzr, [x0]

        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, ulSum]
        ldr     x1, [sp, oAddend1]
        add     x1, x1, #8
        
        ldr     x2, [sp, lIndex]
        ldr     x1, [x1, x2, lsl #3]
        add     x0, x0, x1
        
        str     x0, [sp, ulSum]

        // check for overflow
        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto noOverflow1
        ldr     x0, [sp, ulSum]
        ldr     x1, [sp, oAddend1]
        add     x1, x1, #8
        ldr     x2, [sp, lIndex]
        ldr     x1, [x1, x2, lsl #3]
        cmp     x0, x1
        bhs     noOverflow1
        
        // ulCarry = 1;
        mov     x0, #1
        add     x1, sp, ulCarry
        str     x0, [x1]
        
noOverflow1:    

        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, ulSum]
        ldr     x1, [sp, oAddend2]
        add     x1, x1, #8
        
        ldr     x2, [sp, lIndex]
        ldr     x1, [x1, x2, lsl #3]
        add     x0, x0, x1
        
        str     x0, [sp, ulSum]

        // check for overflow
        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto noOverflow1
        ldr     x0, [sp, ulSum]
        ldr     x1, [sp, oAddend2]
        add     x1, x1, #8
        ldr     x2, [sp, lIndex]
        ldr     x1, [x1, x2, lsl #3]
        cmp     x0, x1
        bhs     noOverflow2
        
        // ulCarry = 1;
        mov     x0, #1
        add     x1, sp, ulCarry
        str     x0, [x1]
        
noOverflow2:

        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, oSum]
        add     x0, x0, #8    // x0 <- pointer to digit array
        ldr     x1, [sp, lIndex]        // x1 <- index
        ldr     x2, [sp, ulSum]         // x2 <- pointer to sum
        str     x2, [x0, x1, lsl #3]

        // lIndex++;
        ldr     x0, [sp, lIndex]
        add     x0, x0, #1
        str     x0, [sp, lIndex]

        // goto startAddLoop;
        b       startAddLoop
        
        // }
        
endAddLoop:
 
        // Check for a carry out of the last "column" of the addition.
        // if (ulCarry != 1) goto noCarry;
        ldr     x0, [sp, ulCarry]
        cmp     x0, #1
        bne     noCarry

        // if (lSumLength != MAX_DIGITS) goto roomToCarry;
        ldr     x0, [sp, lSumLength]
        mov     x1, MAX_DIGITS
        cmp     x0, x1
        bne     roomToCarry

        // return FALSE
        mov     w0, FALSE
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

roomToCarry:
        
        // oSum->aulDigits[lSumLength] = 1;
        ldr     x0, [sp, oSum]
        add     x0, x0, #8
        ldr     x1, [sp, lSumLength]
        mov     x2, #1
        str     x2, [x0, x1, lsl #3]
        
        // lSumLength++;
        ldr     x0, [sp, lSumLength]
        add     x0, x0, #1
        str     x0, [sp, lSumLength]
        
noCarry:

        // Set the length of the sum
        // oSum->lLength = lSumLength;
        ldr     x0, [sp, oSum]
        ldr     x1, [sp, lSumLength]
        str     x1, [x0]

        // return TRUE
        mov     w0, TRUE
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        
//---------------------------------------------------------------------
