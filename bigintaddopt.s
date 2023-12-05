//---------------------------------------------------------------------
// bigintadd.s
// Author: Hugh Peterson
//---------------------------------------------------------------------

        .section .rodata

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
        .equ    LARGER_STACK_BYTECOUNT, 16

        // Local variable registers
        lLarger .req x19

        // Parameter registers
        lLength1 .req x20
        lLength2 .req x21
        
BigInt_larger:
        
        // Prologue
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        mov     lLength1, x0        
        mov     lLength2, x1

        // long lLarger;

        // if (lLength1 <= lLength2) goto twoLarger;
        cmp     lLength1, lLength2
        ble     twoLarger

        // {

        // lLarger = lLength1;
        mov     lLarger, lLength1

        // goto foundLarger;
        b foundLarger

        // }
        
twoLarger:

        // lLarger = lLength2;
        mov     lLarger, lLength2

foundLarger:
        
        // Epilog and return lLarger
        mov     x0, lLarger
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
        .equ    ADD_STACK_BYTECOUNT, 16

        // Local variables
        ulCarry         .req x22
        ulSum           .req x23
        lIndex          .req x24
        lSumLength      .req x25

        // Parameter stack offsets
        oSum            .req x26
        oAddend2        .req x27
        oAddend1        .req x28

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
        mov     oAddend1, x0        
        mov     oAddend2, x1
        mov     oSum, x2

        // determine the larger length
        // lSumLength = BigInt_larger(oAddend1->lLength,
        //      oAddend2->lLength);
        ldr     x0, [oAddend1]
        ldr     x1, [oAddend2]
        bl      BigInt_larger
        mov     lSumLength, x0

        // Clear oSum's array if necessary.
        // if (oSum->lLength <= lSumLength) goto noClear;
        ldr     x0, [oSum]
        cmp     x0, lSumLength
        ble     noClear

        // {

        // memset(oSum->aulDigits, 0, MAX_DIGITS *
        //      sizeof(unsigned long));
        mov     x0, oSum  // x0 <- pointer to oSum
        add     x0, x0, SIZEOF_ULONG
        mov     x1, xzr         // x1 <- 0
        mov     x2, SIZEOF_ULONG        // x2 <- sizeof(unsigned long)
        mov     x3, MAX_DIGITS
        mul     x2, x2, x3
        bl      memset
        
        // }        
noClear:

        // ulCarry = 0;
        // lIndex = 0;
        mov     ulCarry, xzr
        mov     lIndex, xzr

startAddLoop:

        // {

        // if (lIndex >= lSumLength) goto endAddLoop;
        mov     x0, lIndex
        mov     x1, lSumLength
        cmp     x0, x1
        bge     endAddLoop

        // ulSum = ulCarry;
        mov     ulSum, ulCarry

        // ulCarry = 0;
        mov     ulCarry, xzr

        // ulSum += oAddend1->aulDigits[lIndex];
        mov     x0, oAddend1
        add     x0, x0, SIZEOF_ULONG
        ldr     x0, [x0, lIndex, lsl #3]
        add     ulSum, ulSum, x0

        // check for overflow
        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto noOverflow1
        mov     x0, oAddend1
        add     x0, x0, SIZEOF_ULONG
        ldr     x0, [x0, lIndex, lsl #3]
        cmp     ulSum, x0
        bhs     noOverflow1
        
        // ulCarry = 1;
        mov     ulCarry, #1
        
noOverflow1:    

        // ulSum += oAddend2->aulDigits[lIndex];
        mov     x0, oAddend2
        add     x0, x0, SIZEOF_ULONG
        ldr     x0, [x0, lIndex, lsl #3]
        add     ulSum, ulSum, x0

        // check for overflow
        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto noOverflow1
        mov     x0, oAddend2
        add     x0, x0, SIZEOF_ULONG
        ldr     x0, [x0, lIndex, lsl #3]
        cmp     ulSum, x0
        bhs     noOverflow2
        
        // ulCarry = 1;
        mov     ulCarry, #1
        
noOverflow2:

        // oSum->aulDigits[lIndex] = ulSum;
        mov     x0, oSum
        add     x0, x0, SIZEOF_ULONG
        str     ulSum, [x0, lIndex, lsl #3]

        // lIndex++;
        add     lIndex, lIndex, #1

        // goto startAddLoop;
        b       startAddLoop
        
        // }
        
endAddLoop:
 
        // Check for a carry out of the last "column" of the addition.
        // if (ulCarry != 1) goto noCarry;
        cmp     ulCarry, #1
        bne     noCarry

        // if (lSumLength != MAX_DIGITS) goto roomToCarry;
        cmp     lSumLength, MAX_DIGITS
        bne     roomToCarry

        // return FALSE
        mov     w0, FALSE
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

roomToCarry:
        
        // oSum->aulDigits[lSumLength] = 1;
        mov     x0, oSum
        add     x0, x0, SIZEOF_ULONG
        mov     x1, #1
        str     x1, [x0, lSumLength, lsl #3]
        
        // lSumLength++;
        add     lSumLength, lSumLength, #1
        
noCarry:

        // Set the length of the sum
        // oSum->lLength = lSumLength;
        str     lSumLength, [oSum]

        // return TRUE
        mov     w0, TRUE
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)
        
//---------------------------------------------------------------------
