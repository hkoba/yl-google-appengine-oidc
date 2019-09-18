#!/usr/bin/env perl
package YATT_Helper::Google::Metadata;
use strict;
use File::AddInc;
use utf8;

use MOP4Import::Base::CLI_JSON -as_base,
  [fields =>
   qw/_cache/,
   [mock_dir => doc => "Use local files in this dir if it exists instead of metadata server"],
   [prefix => default => 'http://metadata'],
   [location => default => '/computeMetadata/v1/'],
   [header => default => [qw/Metadata-Flavor Google/]],
 ];

use Furl;
use IO::Socket::SSL;

our $instance;
sub instance {
  $instance //= shift->new(@_);
}

sub onconfigure_mock_dir {
  (my MY $self, my $mock_dir) = @_;
  return unless -d $mock_dir;
  $mock_dir =~ s,/*\z,/,;
  $self->{mock_dir} = $mock_dir;
}

sub attribute {
  (my MY $self, my $attName) = @_;
  $self->get("project/attributes/$attName");
}

sub get {
  (my MY $self, my $entry) = @_;
  if ($self->{mock_dir}) {
    $self->cli_read_file($self->{mock_dir}.$entry);
  } else {
    $self->{_cache}{$entry} //= do {
      my $url = $self->{prefix}.$self->{location}.$entry;
      $self->furl_get($url, [@{$self->{header}}]);
    };
  }
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
