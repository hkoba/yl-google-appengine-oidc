#!/usr/bin/env perl
package YATT_Helper::Google::Metadata;
use strict;
use File::AddInc;
use utf8;

use MOP4Import::Base::CLI_JSON -as_base,
  [fields =>
   [prefix => default => 'http://metadata'],
   [port_suffix => default => ''],
   [location => default => '/computeMetadata/v1/'],
   [header => default => [qw/Metadata-Flavor Google/]],
 ];

use Furl;
use IO::Socket::SSL;

sub attribute {
  (my MY $self, my $attName) = @_;
  $self->get("project/attributes/$attName");
}

sub get {
  (my MY $self, my $entry) = @_;
  my $url = $self->{prefix}.$self->{port_suffix}.$self->{location}.$entry;
  $self->furl_get($url, [@{$self->{header}}]);
}

sub furl_get {
  (my MY $self, my @rest) = @_;
  my $res = Furl->new->get(@rest);
  if ($res->is_success) {
    return $res->content;
  } else {
    die $res->status_line;
  }
}

MY->run(\@ARGV) unless caller;
1;
