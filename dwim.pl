#!/usr/bin/perl

# dwim (do what i mean) is my own plan9-like plumber

use v5.24;
use warnings;
use strict;
use Path::ExpandTilde;

die "usage: $0 phrase\n" if scalar @ARGV > 1;
my $p;
$p = $ARGV[0] if defined $ARGV[0];
$p = `xsel -o` if not defined $ARGV[0];

my $OPENER = env (OPENER => "u");
my $EDITOR = env (EDITOR => "vi");
my $MAILER = env (MAILER => "mutt");
my $MAILROOT = env (MAILROOT => "/home/john/mail/");

for ($p) {
	# web address
	if (/^(https?:\/\/.+)$/) {
		exec "firefox", "$1"
	}

	# e-mail address
	if (/^(mailto:\/\/.+)$/ or /^(.+@.+\.\w+)$/) {
		exec $MAILER, "$1"
	}

	# file:line
	if (/^(.+):(\d+)(:.*?)?$/) {
		my $f = path($1);
		exec $OPENER, $EDITOR, "-c", ":$2", "$f"
	}

	# file:query (if file exists)
	if (/^(.+):(.+)$/) {
		my $f = path($1);
		exec $OPENER, $EDITOR, "-c", "/$2", "$f" if -e $f;
		# otherwise fall through
	}

	# maildir (if it matches) or file (if it exists)
	if (/^([^\s]+)$/) {
		my $f = path($1);
		exec $OPENER, $MAILER, "-f", "$f" if $f =~ /^$MAILROOT/; # maildir
		exec $OPENER, $EDITOR, "$f" if -e $f; #file
		# otherwise fall through
	}

	# otherwise
	die "no handler matched by: $p\n"
}

sub path {
	my $f = shift;
	$f = expand_tilde($f);
	return $f if $f =~ /^\// or $f =~ /^~/;
	my $t = `xtitle`;
	chomp $t;
	die "couldn't retrieve directory\n" if ! -d $t and ! -d ($t = dirname $t);
	return "$t/$f";
}

sub env {
	my %h = @_;
	my $k = (keys %h)[0];
	return $ENV{$k} if defined ${ENV}{$k};
	return $h{$k};
}
