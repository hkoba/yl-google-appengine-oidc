#!/usr/bin/env perl
package MyBackend;
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     , [option1 => doc => "some useful option", default => "FOO"]
   ];

MY->run(\@ARGV) unless caller;

1;
