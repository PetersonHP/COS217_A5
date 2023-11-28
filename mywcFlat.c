/*--------------------------------------------------------------------*/
/* mywc.c                                                             */
/* Author: Bob Dondero                                                */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long lLineCount = 0;      /* Bad style. */
static long lWordCount = 0;      /* Bad style. */
static long lCharCount = 0;      /* Bad style. */
static int iChar;                /* Bad style. */
static int iInWord = FALSE;      /* Bad style. */

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

int main(void)
{
  scanloop:
   iChar = getchar();
   if (iChar == EOF) goto endscanloop;
   
   lCharCount++;

   if (!isspace(iChar)) goto checkspaceelse;
   if (!iInWord) goto inword;
   lWordCount++;
   iInWord = FALSE;
  inword:
   goto checkspaceendif;
   
  checkspaceelse:
   if (iInWord) goto notinword;
   iInWord = TRUE;
  notinword:
  checkspaceendif:
   
   if (iChar != '\n') goto newline;
   lLineCount++;
  newline:
   goto scanloop;
  endscanloop:
   
   if (!iInWord) goto trailingword;
   lWordCount++;
  trailingword:

   printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
   return 0;
}
