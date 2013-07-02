Simple C Parser
===============

This is a simple C parser script I wrote for a university project (Principles of Compiler Design course).

scanner.pl and parser.pl are separate and do not depend on each other. A simplified version of scanner.pl is used in parser.pl.

Scanner does the lexical analysis(using regular expressions) and Parser does the syntax analysis.

The simple C grammar along with FIRST and FOLLOW sets and parse table are in the `documents` directory. The LL(1) C grammar is the LL(1) version of Simple C grammar you get after left factoring and left recursion removal.

Text::SimpleTable module is required for drawing symbol table and output of parser. You can install it with cpanminus:

`sudo cpanm Text::SimpleTable`

Usage
-----

Perl scripts should be marked as executable. You can achieve this with the following command:

`chmod +x scanner.pl parser.pl`

Scanning C source code:

`./scanner.pl [file_name]`

Parsing C source code:

`./parser.pl [-s] [file_name]`

`-s` option tells the script to print the symbol table.

If you want to type the C code directly, don't enter the file name. When you finished entering C code, hit Ctrl-D.

If you can't see the whole output in the terminal, pipe it to `less`:

`./parser.pl [-s] [file_name] | less`

Here is some dummy code to show you what can be parsed and scanned:

For scanner:

    /* Multi-line
    comment */
    int main() {
        int i = 2.56e+2;
        // Comment
        char ch = 'a';
        i++;
        i--;
        i*=5;
        i/=2;
        return 0;
    }

For parser:

    main() {
        int a[10];
        int i;
        int j;
        i = 4;
        j=i*6;
        if(j<10) {
            j = j - 1;
        }
        return 0;
    }