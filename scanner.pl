#!/usr/bin/perl

# Simple C Scanner. This program uses regular expressions for lexical analysis of C source code.
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
use Text::SimpleTable;

my (@token, @type, @row, @col, $row, $len, $i);

undef $/;                    # For reading whole file not just one line

my $token_regex = qr/
                        (?<nline>\n) |
                        (?: (?<slash>\/) (?:(?<comment>\*.*?\*\/ | \/[^\n\r]*) | (?<equal>=))? ) |
                        \b(?<keyword>main|int|bool|float|char|void|return|if|else|while|for|continue|break|switch|case)\b |
                        (?<delimiter>\( | \) | \[ | \] | \{ | \} | , | ;) |
                        (?<operator>\+(?:\+|=)? | -(?:-|=)? | (?:\*|=|!|<|>)(?:=)? | && | \|\|) |
                        (?<id>[_a-zA-Z]\w*) |
                        (?<string>"[^\n\r]*?") |
                        (?<character>'[^\n\r]') |
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
        }
        if (defined $+{slash}) {
            $i++;
            if (defined $+{comment}) {
                ($type[$i], $row[$i], $col[$i]) = ("Comment", $row, $-[0]+1-$len);
                my $comment = $+{slash} . $+{comment};
                $row++ while($comment =~ /\n/g);
                $token[$i] = $comment;
            } elsif (defined $+{equal}) {
                ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{slash} . $+{equal}, "Operator", $row, $-[0]+1-$len);
            } else {
                ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{slash}, "Operator", $row, $-[0]+1-$len);
            }
        } elsif (defined $+{keyword}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{keyword}, "Keyword", $row, $-[0]+1-$len);
        } elsif (defined $+{delimiter}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{delimiter}, "Delimiter", $row, $-[0]+1-$len);
        } elsif (defined $+{operator}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{operator}, "Operator", $row, $-[0]+1-$len);
        } elsif (defined $+{id}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{id}, "ID", $row, $-[0]+1-$len);
        } elsif (defined $+{string}) {
            $i++;
            ($type[$i], $row[$i], $col[$i]) = ("String", $row, $-[0]+1-$len);
            my $string = $+{string};
            if ($string =~ /\\[^\\nt"]/) { # If string has unknown escape
                while ($string =~ /(?<escape>\\[^\\nt"])/g) {
                    print "Warning: unknown escape '$+{escape}' on line $row\n";
                    pos($string) = $-[0]; # Going back to remove "\"
                    $string =~ s/\G\\(.)/$1/;
                }
            }
            $token[$i] = $string;
        } elsif (defined $+{character}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{character}, "Character", $row, $-[0]+1-$len);
        } elsif (defined $+{number}) {
            $i++;
            ($token[$i], $type[$i], $row[$i], $col[$i]) = ($+{number}, "Number", $row, $-[0]+1-$len);
        }
    }
    # Printing symbol table
    my $symt = Text::SimpleTable->new([20, 'Token'], [20, 'Type'], [5, 'Row'], [5, 'Col']);
    for my $j (0..$i) {
        $symt->row("$token[$j]", "$type[$j]", "$row[$j]", "$col[$j]");
        $symt->hr;
    }
    print $symt->draw;
}