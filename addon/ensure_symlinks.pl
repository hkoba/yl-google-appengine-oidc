#!/usr/bin/env perl
use strict;
use warnings;

use File::Spec;
use File::Basename;
use File::Find;
use File::Path qw/make_path/;

use autodie;

{
  my $addonDir = dirname(File::Spec->rel2abs(__FILE__));
  my $appDir = dirname($addonDir);
  chdir($addonDir);
  my (@dir, %dir);
  my (%mod);
  foreach my $addon (glob("*")) {
    next unless -d $addon;
    chdir($addon);
    find(sub {
      return if $_ eq '.';
      if (-d $_) {
        return if $dir{$File::Find::name}++;
        (my $name = $File::Find::name) =~ s,^\./,,;
        push @dir, $name;
      } elsif (-f $_ and /\.pm$/) {
        return if $mod{$addon}[0]{$File::Find::name}++;
        (my $name = $File::Find::name) =~ s,^\./,,;
        push @{$mod{$addon}[1]}, $name;
      }
    }, 'lib');
  } continue {
    chdir($addonDir);
  }

  chdir($appDir);

  # print join("\n", @dir), "\n";
  make_path(@dir, {verbose => 1});

  foreach my $addon (keys %mod) {
    my @mod = @{$mod{$addon}[1]};
    foreach my $fn (@mod) {
      my $srcFn = "addon/$addon/$fn";
      my $dstFn = $fn;
      system "ln", "-vnsfr", $srcFn, $dstFn;
    }
  }
}
