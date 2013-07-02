#!/usr/bin/perl

# Simple C Parser. This program scans and parses C source code.
# Copyright (C) 2011, 2013 Siavash Askari Nasr

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Getopt::Std;
use Text::SimpleTable;

getopts("s");
our ($opt_s);

my (@token, @type, @row, @col, $row, $len, $i, @input,  @productions, %production, @stack, $p_index);

undef $/;                   # For reading whole file not just one line

my $token_regex = qr/
                      (?<nline>\n) |
                      \b(?<keyword>main|int|bool|float|void|return|if|else|while|break)\b |
                      (?<delimiter>\( | \) | \[ | \] | \{ | \} | ;) |
                      (?<operator>\+ | - | \* | \/ | % | (?:=|<|>)(?:=)? | != | && | \|\|) |
                      (?<id>[_a-zA-Z]\w*) |
                      (?<number>\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?)
                  /xs;

while (<>) {
    $row = 1;
    $len = 0;
    $i = -1;
    while (/$token_regex/g) {
        if (defined $+{nline}) {
            $len = $+[0]; # Putting each end of line index in $len for calculating columns
            $row++;       # End of line, so add one to $row
        } elsif (defined $+{keyword}) {
            $i++;
            ($token[$i], $type[$i], $input[$i], $row[$i], $col[$i]) = ($+{keyword}, "Keyword", $+{keyword}, $row, $-[0]+1-$len);
        } elsif (defined $+{delimiter}) {
            $i++;
            ($token[$i], $type[$i], $input[$i], $row[$i], $col[$i]) = ($+{delimiter}, "Delimiter", $+{delimiter}, $row, $-[0]+1-$len);
        } elsif (defined $+{operator}) {
            $i++;
            ($token[$i], $type[$i], $input[$i], $row[$i], $col[$i]) = ($+{operator}, "Operator", $+{operator}, $row, $-[0]+1-$len);
        } elsif (defined $+{id}) {
            $i++;
            ($token[$i], $type[$i], $input[$i], $row[$i], $col[$i]) = ($+{id}, "ID", "ID", $row, $-[0]+1-$len);
        } elsif (defined $+{number}) {
            $i++;
            ($token[$i], $type[$i], $input[$i], $row[$i], $col[$i]) = ($+{number}, "Number", "Number", $row, $-[0]+1-$len);
        }
    }
    # Printing symbol table
    if (defined $opt_s) {
        my $symt = Text::SimpleTable->new([20, 'Token'], [20, 'Type'], [5, 'Row'], [5, 'Col']);
        for my $j (0..$i) {
            $symt->row("$token[$j]", "$type[$j]", "$row[$j]", "$col[$j]");
            $symt->hr;
        }
        print $symt->draw;
    }

    # Parser
    @productions = (
                    [qw/ main ( ) Compound-stmt /], #1
                    [qw/ { Local-declarations Stmt-list } /],       #2
                    [qw/ E L /],                                    #3
                    [qw/ Var-declarations L /],                     #4
                    [qw/ E /],                                      #5
                    [qw/ Type-specifier ID V /],                    #6
                    [qw/ ; /],                                      #7
                    [qw/ [ Number ] ; /],                           #8
                    [qw/ int /],                                    #9
                    [qw/ void /],                                #10
                    [qw/ bool /],                                #11
                    [qw/ float /],                               #12
                    [qw/ E S /],                                 #13
                    [qw/ Stmt S /],                              #14
                    [qw/ E /],                                   #15
                    [qw/ Expression-stmt /],                     #16
                    [qw/ Compound-stmt /],                       #17
                    [qw/ Selection-stmt /],                      #18
                    [qw/ Iteration-stmt /],                      #19
                    [qw/ Return-stmt /],                         #20
                    [qw/ Break-stmt /],                          #21
                    [qw/ if ( Expression ) Compound-stmt Selection /], #22
                    [qw/ else Compound-stmt /],    #23
                    [qw/ E /],                     #24
                    [qw/ while ( Expression ) Compound-stmt /], #25
                    [qw/ return Return /],                      #26
                    [qw/ ; /],                                  #27
                    [qw/ Expression ; /],                       #28
                    [qw/ break ; /],                            #29
                    [qw/ Var = Expression ; /],                 #30
                    [qw/ Operand Exp /],                        #31
                    [qw/ Operator Operand /],                   #32
                    [qw/ E /],                                  #33
                    [qw/ Number /],                             #34
                    [qw/ Var /],                                #35
                    [qw/ ID Var2 /],                            #36
                    [qw/ [ Number ] /],                         #37
                    [qw/ E /],                                  #38
                    [qw/ RelOp /],                              #39
                    [qw/ LogicOp /],                            #40
                    [qw/ ArithOp /],                            #41
                    [qw/ <= /],                                 #42
                    [qw/ < /],                                  #43
                    [qw/ >= /],                                 #44
                    [qw/ > /],                                  #45
                    [qw/ != /],                                 #46
                    [qw/ == /],                                 #47
                    [qw/ && /],                                 #48
                    [qw/ || /],                                 #49
                    [qw/ + /],                                  #50
                    [qw/ - /],                                  #51
                    [qw/ * /],                                  #52
                    [qw# / #],                                  #53
                    [qw/ % /],                                  #54
                   );
    $production{"Program"}{"main"} = 1;
    $production{"Compound-stmt"}{"{"} = 2;
    ($production{"Local-declarations"}{"{"}, $production{"Local-declarations"}{"}"}, $production{"Local-declarations"}{"int"}, $production{"Local-declarations"}{"void"}, $production{"Local-declarations"}{"bool"}, $production{"Local-declarations"}{"float"}, $production{"Local-declarations"}{"if"}, $production{"Local-declarations"}{"while"}, $production{"Local-declarations"}{"return"}, $production{"Local-declarations"}{"break"}, $production{"Local-declarations"}{"ID"}) = (3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
    ($production{"L"}{"{"}, $production{"L"}{"}"}, $production{"L"}{"int"}, $production{"L"}{"void"}, $production{"L"}{"bool"}, $production{"L"}{"float"}, $production{"L"}{"if"}, $production{"L"}{"while"}, $production{"L"}{"return"}, $production{"L"}{"break"}, $production{"L"}{"ID"}) = (5, 5, 4, 4, 4, 4, 5, 5, 5, 5, 5);
    ($production{"Var-declarations"}{"int"}, $production{"Var-declarations"}{"void"}, $production{"Var-declarations"}{"bool"}, $production{"Var-declarations"}{"float"}) = (6, 6, 6, 6);
    ($production{"V"}{"["}, $production{"V"}{";"}) = (8, 7);
    ($production{"Type-specifier"}{"int"}, $production{"Type-specifier"}{"void"}, $production{"Type-specifier"}{"bool"}, $production{"Type-specifier"}{"float"}) = (9, 10, 11, 12);
    ($production{"Stmt-list"}{"{"}, $production{"Stmt-list"}{"}"}, $production{"Stmt-list"}{"if"}, $production{"Stmt-list"}{"while"}, $production{"Stmt-list"}{"return"}, $production{"Stmt-list"}{"break"}, $production{"Stmt-list"}{"ID"}) = (13, 13, 13, 13, 13, 13, 13);
    ($production{"S"}{"{"}, $production{"S"}{"}"}, $production{"S"}{"if"}, $production{"S"}{"while"}, $production{"S"}{"return"}, $production{"S"}{"break"}, $production{"S"}{"ID"}) = (14, 15, 14, 14, 14, 14, 14);
    ($production{"Stmt"}{"{"}, $production{"Stmt"}{"if"}, $production{"Stmt"}{"while"}, $production{"Stmt"}{"return"}, $production{"Stmt"}{"break"}, $production{"Stmt"}{"ID"}) = (17, 18, 19, 20, 21, 16);
    $production{"Selection-stmt"}{"if"} = 22;
    ($production{"Selection"}{"{"}, $production{"Selection"}{"}"}, $production{"Selection"}{"if"}, $production{"Selection"}{"while"}, $production{"Selection"}{"return"}, $production{"Selection"}{"break"}, $production{"Selection"}{"ID"}, $production{"Selection"}{"else"}) = (24, 24, 24, 24, 24, 24, 24, 23);
    $production{"Iteration-stmt"}{"while"} = 25;
    $production{"Return-stmt"}{"return"} = 26;
    ($production{"Return"}{";"}, $production{"Return"}{"ID"}, $production{"Return"}{"Number"}) = (27, 28, 28);
    $production{"Break-stmt"}{"break"} = 29;
    $production{"Expression-stmt"}{"ID"} = 30;
    ($production{"Expression"}{"ID"}, $production{"Expression"}{"Number"}) = (31, 31);
    ($production{"Exp"}{")"}, $production{"Exp"}{";"}, $production{"Exp"}{"<="}, $production{"Exp"}{"<"}, $production{"Exp"}{">="}, $production{"Exp"}{">"}, $production{"Exp"}{"!="}, $production{"Exp"}{"=="}, $production{"Exp"}{"&&"}, $production{"Exp"}{"||"}, $production{"Exp"}{"+"}, $production{"Exp"}{"-"}, $production{"Exp"}{"*"}, $production{"Exp"}{"/"}, $production{"Exp"}{"%"}) = (33, 33, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32);
    ($production{"Operand"}{"ID"}, $production{"Operand"}{"Number"}) = (35, 34);
    $production{"Var"}{"ID"} = 36;
    ($production{"Var2"}{")"}, $production{"Var2"}{"["}, $production{"Var2"}{";"}, $production{"Var2"}{"<="}, $production{"Var2"}{"<"}, $production{"Var2"}{">="}, $production{"Var2"}{">"}, $production{"Var2"}{"!="}, $production{"Var2"}{"=="}, $production{"Var2"}{"="}, $production{"Var2"}{"&&"}, $production{"Var2"}{"||"}, $production{"Var2"}{"+"}, $production{"Var2"}{"-"}, $production{"Var2"}{"*"}, $production{"Var2"}{"/"}, $production{"Var2"}{"%"}) = (38, 37, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38);
    ($production{"Operator"}{"<="}, $production{"Operator"}{"<"}, $production{"Operator"}{">="}, $production{"Operator"}{">"}, $production{"Operator"}{"!="}, $production{"Operator"}{"=="}, $production{"Operator"}{"&&"}, $production{"Operator"}{"||"}, $production{"Operator"}{"+"}, $production{"Operator"}{"-"}, $production{"Operator"}{"*"}, $production{"Operator"}{"/"}, $production{"Operator"}{"%"}) = (39, 39, 39, 39, 39, 39, 40, 40, 41, 41, 41, 41, 41);
    ($production{"RelOp"}{"<="}, $production{"RelOp"}{"<"}, $production{"RelOp"}{">="}, $production{"RelOp"}{">"}, $production{"RelOp"}{"!="}, $production{"RelOp"}{"=="}) = (42, 43, 44, 45, 46, 47);
    ($production{"LogicOp"}{"&&"}, $production{"LogicOp"}{"||"}) = (48, 49);
    ($production{"ArithOp"}{"+"}, $production{"ArithOp"}{"-"}, $production{"ArithOp"}{"*"}, $production{"ArithOp"}{"/"}, $production{"ArithOp"}{"%"}) = (50, 51, 52, 53, 54);

    push @input, '$';
    push @stack, ('$', "Program");
    my $production_table = Text::SimpleTable->new([20, 'Stack'], [28, 'Input'], [20, 'Production']);
    my (@production, @stack2, @input2);
    while ($stack[-1] ne '$') {
        @stack2 = @stack;
        @input2 = @input;
        @production = ();
        if ($stack[-1] eq $input[0]) {
            shift @input;
            pop @stack;
        } else {
            if (defined $production{$stack[-1]}{$input[0]}) {
                $p_index = $production{$stack[-1]}{$input[0]} - 1;
                pop @stack;
                for my $j (reverse 0..$#{ $productions[$p_index] }) {
                    push(@stack, $productions[$p_index][$j]) if $productions[$p_index][$j] ne "E";
                    unshift(@production, $productions[$p_index][$j]);
                }
            } else {
                print "An error occurred on token \"$input[0]\".\n";
                last;
            }
        }
        $production_table->row("@stack2", "@input2", @production ? "${stack2[-1]} -> @production" : '');
        $production_table->hr;
    }
    $production_table->row("@stack", "@input", "@production");
    print $production_table->draw;
    print "Parse done successfully.\n" if($stack[-1] eq '$' and $input[0] eq '$');
}