package YATT_Helper::OIDC::Session;
# -*- coding: utf-8 -*-
use strict;
use warnings;

use MOP4Import::Declare -as_base;
# ↑冗長よね…
use MOP4Import::Types
  (Session => [[fields => qw/
                              ssri.jump
                              provider
                              survey_key
                              panel
                              callback.nocode_action
                              provider_error
                            /]]
   , ProviderRec => [[fields => qw/
                                    access_token
                                    userinfo
                                    scope_ext
                                  /]]
   , AccessToken => [[fields => qw/
                                    access_token
                                    refresh_token
                                    expires_at
                                    id_token
                                    decoded_id_token
                                  /]]
 );

1;
