#!/usr/bin/env perl
package YATT_Helper::OIDC;
use strict;
use warnings;
use File::AddInc;

use MOP4Import::Base::CLI_JSON -as_base
  , [fields => qw/
                   provider_name
                   provider_uri_base
                   client_id
                   client_secret
                   redirect_uri_base
                   redirect_location
                   scope
                   authorization_endpoint
                   userinfo_endpoint
                   token_endpoint
                   use_basic_schema
                   extra
                   /
     , [time_margin_secs => default => 60]
   ];

use YATT_Helper::OIDC::Session qw/
                        Session
                        ProviderRec
                        AccessToken
                      /;

use OIDC::Lite::Client::WebServer;
use OIDC::Lite::Model::IDToken;
use HTTP::Request ();
use LWP::UserAgent ();

#========================================

sub join_provider_uri {
  (my MY $self, my $location) = @_;
  join(""
         , $self->{provider_uri_base} // ''
         , $location);
}

sub CLIENT {'OIDC::Lite::Client::WebServer'}
sub client {
  (my MY $self) = @_;
  $self->CLIENT->new(
    id => $self->{client_id}
    , secret => $self->{client_secret}
    , authorize_uri => $self->join_provider_uri($self->{authorization_endpoint})
    , access_token_uri => $self->join_provider_uri($self->{token_endpoint})
  );
}

sub state_to_authorization {
  (my MY $self, my $session) = @_;

  my $state = $self->generate_state($session, $self->{provider_name}); # XXX:
  $self->set_state($session, $state);

  $state;
}

sub url_to_authorization {
  (my MY $self, my ($session, @rest)) = @_;

  my $state = $self->state_to_authorization($session);

  my @extra = do {
    if ($self->{extra} or @rest) {
      my %extra;
      %extra = %{$self->{extra}} if $self->{extra};
      while (my ($k, $v) = splice @rest, 0, 2) {
        $extra{$k} = $v;
      }
      (extra => \%extra);
    } else {
      ();
    }
  };

  $self->client($self)->uri_to_redirect(
    redirect_uri => $self->redirect_uri
    , scope => $self->custom_scope($session)
    , state => $state
    , @extra
  );
}

sub custom_scope {
  (my MY $self, my Session $session) = @_;

  my ProviderRec $provider_rec = $session->{provider}{$self->{provider_name}}
    //= +{};

  if ($provider_rec->{scope_ext}) {
    join(" ", $self->{scope}, $provider_rec->{scope_ext})
  } else {
    $self->{scope}
  }
}


sub redirect_uri {
  (my MY $self) = @_;
  $self->{redirect_uri_base} . $self->{redirect_location};
}

#----------------------------------------

sub verify_state_with_session {
  (my MY $self, my ($state, $session)) = @_;

  my $session_state = $self->get_state($session);

  unless ($state and $session_state and $state eq $session_state) {
    return ["The state parameter is missing or not matched with session."
            , $state, $session_state
            # , [session => $session]
          ];
  }
  undef;
}

sub callback_nocode_action {
  (my MY $self, my Session $session) = @_;
  delete $session->{'callback.nocode_action'};
}

sub get_access_client_token {
  (my MY $self, my $code) = @_;

  my $client = $self->client;
  my $token = $client->get_access_token(
    code => $code
      , redirect_uri => $self->redirect_uri
      , ($self->{use_basic_schema} ? (use_basic_schema => 1) : ())
  );

  ($client, $token);
}

sub get_userinfo {
  (my MY $self, my Session $session, my $filter) = @_;

  my ProviderRec $provider = $self->get_provider_rec($session);

  my AccessToken $atok = $provider->{access_token};

  my $req = HTTP::Request->new(GET => $self->join_provider_uri($self->{userinfo_endpoint}));

  $req->header(Authorization => sprintf("Bearer %s", $atok->{access_token}));

  my $uinfo_res = LWP::UserAgent->new->request($req);

  if (not $uinfo_res->is_success) {
    (undef, [$uinfo_res->code, $uinfo_res->content]);
  } elsif ($filter) {
    my $json = $self->cli_decode_json($uinfo_res->content);
    $self->filter_json_by($filter, $json)
  } else {
    ($uinfo_res->content)
  }
}

sub filter_json_by {
  (my MY $self, my ($filter, $json)) = @_;
  if (not defined $filter or $filter eq 1) {
    $json
  } elsif (not ref $filter) {
    $json->{$filter}
  } elsif (ref $filter eq 'ARRAY') {
    my %dict;
    $dict{$_} = $json->{$_} for @$filter;
    \%dict;
  } else {
    Carp::croak("Invalid filter spec!");
  }
}

#----------------------------------------

sub IDTOKEN_PARSER {'OIDC::Lite::Model::IDToken'}
sub parse_id_token {
  (my MY $self, my $token_string) = @_;
  $self->IDTOKEN_PARSER->load($token_string);
}

#----------------------------------------
use Crypt::OpenSSL::Random qw/random_pseudo_bytes/;

# XXX: state を（使用後も）残すメリットって、何？
sub generate_state {
  (my MY $self, my $session) = @_;
  return $self->get_state($session)
    || unpack("H*", $self->{provider_name}.random_pseudo_bytes(32));
}

#========================================

sub get_provider_rec {
  (my MY $self, my Session $session) = @_;

  $session->{provider}{$self->{provider_name}}
}

sub get_provider_access_token {
  (my MY $self, my Session $session) = @_;

  my ProviderRec $provider = $session->{provider}{$self->{provider_name}}
    or return undef;

  $provider->{access_token};
}

# XXX: もう少し細かく分けたほうが便利だろうけれど。
sub has_live_access_token {
  (my MY $self, my Session $session) = @_;

  my ProviderRec $provider_rec = $session->{provider}{$self->{provider_name}}
    or return 0;

  my AccessToken $atok = $provider_rec->{access_token}
    or return 0;

  return $atok->{expires_at}
    && (time + $self->{time_margin_secs}) < $atok->{expires_at}
}

sub set_provider_access_token {
  (my MY $self, my Session $session, my $access_token_obj) = @_;

  my ProviderRec $provider = $session->{provider}{$self->{provider_name}} //= +{};

  if ($access_token_obj) {
    my AccessToken $atok = +{};
    $atok->{access_token} = $access_token_obj->access_token;
    $atok->{refresh_token} = $access_token_obj->refresh_token;
    $atok->{expires_at} = time + $access_token_obj->expires_in;
    $atok->{id_token} = $access_token_obj->id_token;

    $provider->{access_token} = $atok;
  } else {
    delete $provider->{access_token};
  }
  "";
}

sub set_provider_userinfo {
  (my MY $self, my Session $session, my $userinfo) = @_;

  my ProviderRec $provider = $session->{provider}{$self->{provider_name}} //= +{};

  $provider->{userinfo} = $userinfo;

  "";
}

#========================================

sub get_state {
  (my MY $self, my $session) = @_;
  unless (defined $session) {
    Carp::croak "session hash is empty!";
  }

  $session->{"state_$self->{provider_name}"};
}

sub set_state {
  (my MY $self, my ($session, $state)) = @_;
  unless (defined $session) {
    Carp::croak "session hash is empty!";
  }
  $session->{"state_$self->{provider_name}"} = $state;
}

sub get_server_state {
  (my MY $self, my $session) = @_;
  unless (defined $session) {
    Carp::croak "session hash is empty!";
  }
  $session->{"server_state_$self->{provider_name}"};
}

sub set_server_state {
  (my MY $self, my ($session, $state)) = @_;
  unless (defined $session) {
    Carp::croak "session hash is empty!";
  }
  $session->{"server_state_$self->{provider_name}"} = $state;
}

#========================================

sub set_provider_error {
  (my MY $self, my Session $session, my ($error, $desc, @rest)) = @_;

  # [0] is $error
  # [-1] is $error_description
  $session->{provider_error}{$self->{provider_name}}
    = [$error, @rest, $desc];

  "";
}

#========================================

MY->run(\@ARGV) unless caller;

1;
