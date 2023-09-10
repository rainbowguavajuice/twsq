#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Getopt::Long;
use Text::Template;
use Data::Dumper;

use constant {
    TMPL_DIR => 'template/',
    PAGES    => 'pages/',
    SRC_DIR  => 'src/',
    PML_DIR  => 'permalink/',
    TYPE_CH  => { C => 'convo', P => 'plain', Q => 'quote'},
};


my $BASE = '/';
# for local development. note that the --base option should be
# supplied when deploying, since the opengraph attributes require
# absolute urls.

GetOptions(
    'base=s'   => \$BASE,
    'gh-pages' => sub { $BASE = 'https://rainbowguavajuice.github.io/twsq/'; });

my ($dh, $fh);

# load templates.
opendir $dh, TMPL_DIR;
my %tmpl = map {
    my $tmpl_path = TMPL_DIR.$_;
    if (-f $tmpl_path and /(.+)\.tmpl/) {
	print "load template $tmpl_path\n";
	("$1", Text::Template->new(SOURCE => $tmpl_path));
    } else { (); }
} readdir $dh;
closedir $dh;

# generate sorted list of all source files.
opendir $dh, SRC_DIR;
my @src = map {
    my $src_path = SRC_DIR.$_;
    (-f $src_path and /(\d{4}-\d{2}-\d{2})([a-z]+)([CPQ])/)
	? ([
	($1 =~ tr/-//rd).$2, # generate alphanumeric id
	$1,
	TYPE_CH->{$3},
	$src_path
	   ]) : ();
} reverse sort readdir $dh;
closedir $dh;

# generate list of info pages
opendir $dh, PAGES;
my @pages = map { (-f PAGES.$_ and /(.+)\.html/) ? ($1) : () } readdir $dh;
closedir $dh;

# formats a single entry. returns a pair of strings ($meta, $text).
sub fmt_entry {    
    my ($id, $date, $type, $path) = @_;

    # print "formatting $path\n";

    open $fh, '<', $path;
    chomp (my $head = <$fh>);
    chomp (my $tail = do { local $/; <$fh> });
    close $fh;

    my $body = $tmpl{$type}->fill_in(
	STRICT => 1,
	HASH   => { raw => $tail });

    (
     $tmpl{meta}->fill_in(
	 STRICT => 1,
	 HASH   => {
	     base  => $BASE,
	     title => ($head eq '') ? 'twsq.' : "twsq: $head",
	     url   => $BASE.PML_DIR.$id.'.html',
	     desc  => $tail,
	     date  => $date
	 }),
     $tmpl{entry}->fill_in(
	 STRICT => 1,
	 HASH   => {
	     id    => $id,
	     type  => $type,
	     title => $head,
	     body  => $body,
	     date  => $date
	 })
    );
}

# format a single own page, returns ($meta, $text)
sub fmt_page {
    my ($name) = @_;
    my $path   = PAGES.$name.'.html';

    open $fh, '<', $path;
    my $body = do { local $/; <$fh> };
    close $fh;
    (
     $tmpl{meta}->fill_in(
    	 STRICT => 1,
    	 HASH   => {
    	     base  => $BASE,
    	     title => "twsq: $name",
    	     url   => $BASE.$name.'.html',
    	     desc  => "$name page for twsq.",
    	     date  => '2020'
    	 }),
     $body
    );
}

# write to info pages
foreach (@pages) {
    my ($m, $t) = fmt_page $_;
    open $fh, '>', "$_.html";
    $tmpl{index}->fill_in(
	STRICT => 1,
	HASH   => { meta => $m, main => $t },
	OUTPUT => $fh);
    close $fh;
}

# write to permalink pages
my $all_text = '';

foreach (@src) {
    my ($id, $date, $type,  $path) = @{$_};

    print "generate page $id\n";

    my ($meta, $text) = fmt_entry @{$_};
    $all_text .= $text;

    open $fh, '>', PML_DIR.$id.'.html';
    $tmpl{index}->fill_in(
	STRICT => 1,
	HASH   => { meta => $meta, main => $text },
	OUTPUT => $fh);
    close  $fh;
}

# write to index page
print "generate index\n";

my $all_meta = $tmpl{meta}->fill_in(
    STRICT => 1,
    HASH   => {
	base  => $BASE,
	title => 'twsq.',
	url   => $BASE,
	desc  => 'important words',
	date  => '2020'
    });

open $fh, '>', 'index.html';
$tmpl{index}->fill_in(
    STRICT => 1,
    HASH   => {	meta => $all_meta, main => $all_text },
    OUTPUT => $fh);
close $fh;

# generate javascript
print "generate script(s)\n";
open $fh, '>', 'random.js';
my @paths = map { PML_DIR.($_->[0]).'.html' } @src;
$tmpl{random}->fill_in(
    STRICT => 1,
    HASH   => {	paths => \@paths },
    OUTPUT => $fh);
close $fh;
