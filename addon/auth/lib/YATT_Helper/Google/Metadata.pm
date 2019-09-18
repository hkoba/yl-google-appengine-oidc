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

sub project_attribute {
  (my MY $self, my ($attName, @default)) = @_;
  $self->get("project/attributes/$attName", @default);
}

sub get {
  (my MY $self, my ($entry, @default)) = @_;
  $self->{_cache}{$entry} //= do {
    if ($self->{mock_dir}) {
      my $fn = $self->{mock_dir}.$entry;
      if (-e $fn) {
        $self->cli_read_file($fn);
      } elsif (@default) {
        $default[0];
      } else {
        Carp::croak "Can't read from mocked metadata: $fn";
      }
    } else {
      my $url = $self->{prefix}.$self->{location}.$entry;
      my ($data, $err) = $self->furl_get($url, [@{$self->{header}}]);
      if (not $err) {
        $data;
      } elsif (@default) {
        $default[0]
      } else {
        Carp::croak $err;
      }
    }
  };
}

sub furl_get {
  (my MY $self, my @rest) = @_;
  my $res = Furl->new->get(@rest);
  if ($res->is_success) {
    ($res->content, undef);
  } else {
    (undef, $res->status_line);
  }
}

MY->run(\@ARGV) unless caller;
1;
