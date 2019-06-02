#!/usr/bin/perl

# dwim (do what i mean) is my own plan9-like plumber

use v5.24;
use warnings;
use strict;
use Path::ExpandTilde;
use subs qw/path env handle fail arguments/;

my ($phrase, %o) = arguments "usage: $0 parse\n", 1, d => 0;
$phrase = `xsel -o` if not defined $phrase;

my @LAUNCHER = split /\s/, env(OPENER => "urxvtc -e");
my @EDITOR = split /\s/, env(EDITOR => "vi");
my @MAILER = split /\s/, env(MAILER => "mutt");
my @MAILDIR_VIEWER = split /\s/, env(MAILDIR_VIEWER => "mutt -f");
my $MAILROOT = env(MAILROOT => "/home/john/mail/");

our $handler;

for ($phrase) {
	if (/^(https?:\/\/.+)$/) {
		handle "web address";
		exec "firefox", "$1"
	}

	if (/^(mailto:\/\/.+)$/ or /^(.+@.+\.\w+)$/) {
		handle "e-mail address";
		exec @MAILER, "$1"
	}

	if (/^(.+):(\d+)(:.*?)?$/) {
		handle "file:line";
		my $p = path($1);
		exec @LAUNCHER, @EDITOR, "-c", ":$2", "$p"
	}

	if (/^(.+):(.+)$/) {
		handle "file:query (like grep)";
		my $p = path($1);
		exec @LAUNCHER, @EDITOR, "-c", "/$2", "$p" if -e $p;
		fail "file not found" if $o{d};
		# otherwise fall through
	}

	if (/^([^\s]+)$/) {
		handle "maildir / directory / file";
		my $p = path($1);
		exec @LAUNCHER, @MAILDIR_VIEWER, "$p" if $p =~ /^$MAILROOT/; # maildir
		exec @LAUNCHER, @EDITOR, "$p" if -e $p; #file
		fail "file not found" if $o{d};
		# otherwise fall through
	}

	# otherwise
	die "no handler matched by: $phrase\n"
}

sub path {
	my $n = shift;
	$n = expand_tilde($n);
	return $n if $n =~ /^\// or $n =~ /^~/;
	my $d = `xtitle`;
	chomp $d;
	die "couldn't retrieve current directory\n" if ! -d $d and ! -d ($d = dirname $d);
	return "$d/$n";
}

# take K => V and return environment variable K if defined, otherwise V
sub env {
	my %h = @_;
	my $k = (keys %h)[0];
	return $ENV{$k} if defined ${ENV}{$k};
	return $h{$k};
}

sub handle {
	$handler = shift;
	print STDERR "$handler MATCHED\n" if $o{d};
}

sub fail {
	my $msg = shift;
	print STDERR "$handler FAILED: $msg\n";
}

# parse ARGV and return list of positionals and hash of option values
sub arguments {
	my $usage = shift;  # usage string
	my $n = shift;      # number of positional arguments
	my %options = @_;   # option specification

	# parse options (end upon --)

	while ($_ = shift @ARGV) {
		last if /^--$/;
		unshift @ARGV, $_ and last if not /^-/;

		s/^-//;
		if (defined $options{$_}) { $options{$_} = 1 }
		else { die $usage; }
	}

	# fill @positionals with $n strings (with undef upon empty ARGV)

	my @positionals;
	my $i = 0;
	while (++$i <= $n) {
		if ($_ = shift @ARGV) { push @positionals, $_ }
		else { push @positionals, undef }
	}

	die $usage if @ARGV; # all processing should be done

	return @positionals, %options;
}
