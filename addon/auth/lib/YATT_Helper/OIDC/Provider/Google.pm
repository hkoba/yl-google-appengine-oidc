#!/usr/bin/env perl
package YATT_Helper::OIDC::Provider::Google;
use strict;
use File::AddInc;
use YATT_Helper::OIDC -as_base
  , [fields =>
     [provider_name =>
      default => 'Google'],
     [authorization_endpoint =>
      default => 'https://accounts.google.com/o/oauth2/auth'],
     [token_endpoint =>
      default => 'https://accounts.google.com/o/oauth2/token'],
     [userinfo_endpoint =>
      default => 'https://www.googleapis.com/oauth2/v3/userinfo'],
     [scope =>
      default => 'openid email profile'],
   ]
  ;

MY->run(\@ARGV) unless caller;

1;
