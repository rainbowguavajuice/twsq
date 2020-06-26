#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use 5.012;

sub fmt_convo {
    my @lines = split "\n", $_[0];
    my $ret = "<table>\n";
    
    while (@lines) {
	my $attr = shift @lines;
	my $line = shift @lines;
	$ret .=
	    "<tr>"
	    ."<td class=\"attr\">$attr</td>"
	    ."<td class=\"line\">$line</td>"
	    ."</tr>";
    }
    return $ret . "</table>";
}


sub fmt_quote {
    my ($attr, $line) = split ":\n", $_[0];
    return
	"<div class=\"line\">$line</div>"
	. "<div class=\"attr\"> &mdash; $attr</div>";
}

sub fmt_entry {
    my ($type, $title, $content, $timestamp) = @_;

    my %entry_cl = (Q => 'entry-quote',
		    C => 'entry-convo');
    my %fmt_sub  = (Q => \&fmt_quote,
		    C => \&fmt_convo);

    return
	"<div class=\"entry $entry_cl{$type}\">"
	. (($title eq '') ? '' : "<h2>$title</h2>")
	. $fmt_sub{$type}->($content)
    	. "<div class=\"timestamp\">$timestamp</div>"
	. "</div>";

    
}


my $src_dir = 'src';
opendir (my $dh, $src_dir);

my @posts = map {
    if (m/^(\d{4}-\d{2}-\d{2})(Q|C)[a-z]*$/) {

	open my $fh, '<:encoding(UTF-8)', "$src_dir/$_";
	my @args = do { local $/; split "\n", <$fh>, 2; };
	close $fh;

	fmt_entry $2, @args, $1;

    }
} (reverse sort readdir $dh);

closedir $dh;

my $head =
    '<!DOCTYPE html>
    <html>
    <meta charset="utf-8">
    <html lang="en-GB">
    <head>
    <link href="https://fonts.googleapis.com/css2?family=Vollkorn&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="resources/css/main.css"> 
    <title>do not attempt to comb the timey wimey ball</title>
    </head>
    <body>
    <div class="main">
    <header><h1>twsq.</h1></header>';

my $tail =
    '</div>
    </body>
    </html>';

print join '', $head, @posts, $tail;
