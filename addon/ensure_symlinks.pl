#!/usr/bin/env perl
use strict;
use warnings;

use File::Spec;
use File::Basename;
use File::Find;
use File::Path qw/make_path remove_tree/;

use autodie;

{
  my $addonDir = dirname(File::Spec->rel2abs(__FILE__));
  my $appDir = dirname($addonDir);
  chdir($addonDir);
  my @addon = grep {-d and -d "$_/public" and -d "$_/lib"} glob("*");
  my (@dir, %dir);
  my (%mod);
  foreach my $addon (@addon) {
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

  foreach my $addon (@addon) {
    my $srcFn = "addon/$addon/public";
    my $dstFn = "public/$addon";
    next if -l $dstFn and -r $dstFn;
    if (-d $dstFn) {
      remove_tree $dstFn, +{verbose => 1};
    }
    system "ln", "-vnsfr", $srcFn, $dstFn;
  }

  foreach my $addon (keys %mod) {
    my @mod = @{$mod{$addon}[1]};
    foreach my $fn (@mod) {
      my $srcFn = "addon/$addon/$fn";
      my $dstFn = $fn;
      next if -l $dstFn and -r $dstFn;
      system "ln", "-vnsfr", $srcFn, $dstFn;
    }
  }
}
