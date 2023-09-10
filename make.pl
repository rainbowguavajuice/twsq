#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Text::Template;
use Data::Dumper;

use constant {
    TMPL_DIR => 'template',
    SRC_DIR  => 'src',
    OUT_DIR  => '.',
    PML_DIR  => 'permalink',
    TYPE_CH  => { C => 'convo', P => 'plain', Q => 'quote'},
};

my ($dh, $fh);

# load templates.
opendir $dh, TMPL_DIR;
my %tmpl = map {
    my $tmpl_path = TMPL_DIR.'/'.$_;
    if (-f $tmpl_path and /(.+)\.tmpl/) {
	print "load template $tmpl_path\n";
	($1, Text::Template->new(SOURCE => $tmpl_path));
    }
} readdir $dh;
closedir $dh;


# generate sorted list of all source files.
opendir $dh, SRC_DIR;
my @src = map {
    my $src_path = SRC_DIR.'/'.$_;
    (-f $src_path and /(\d{4}-\d{2}-\d{2})([a-z]+)([CPQ])/)
	? ([
	($1 =~ tr/-//rd).$2, # generate alphanumeric id
	$1,
	TYPE_CH->{$3},
	$src_path
	   ]) : ();
} reverse sort readdir $dh;
closedir $dh;

# formats a single entry.
sub fmt_entry {    
    my ($id, $date, $type, $path) = @_;

    # print "formatting $path\n";
    
    open $fh, "<", $path;
    chomp (my $head = <$fh>);
    chomp (my $tail = do { local $/; <$fh> });
    close $fh;

    my $body = $tmpl{$type}->fill_in(
	STRICT => 1,
	HASH   => { raw => $tail });

    $tmpl{entry}->fill_in(
	STRICT => 1,
	HASH   => {
	    id    => $id,
	    type  => $type,
	    title => $head,
	    body  => $body,
	    date  => $date
	});
}

# write to index and permalink pages
my $all_entries = '';

foreach (@src) {
    my ($id, $date, $type,  $path) = @{$_};

    print "generate page $id\n";
    
    my $entry = fmt_entry @{$_};
    $all_entries .= $entry;
    
    open $fh, '>', PML_DIR."/$id.html";
    $tmpl{index}->fill_in(
	OUTPUT => $fh,
	STRICT => 1,
	HASH   => {
	    meta => '<base href="/twsq/">',
	    main => $entry
	});
    close  $fh;
}

print "generate index\n";
open $fh, '>', 'index.html';
$tmpl{index}->fill_in(
    STRICT => 1,
    HASH   => {
	meta => '<base href="/twsq/">',
	main => $all_entries
    },
    OUTPUT => $fh);
close $fh;
