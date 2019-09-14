use strict;

use YATT::Lite qw/*CON/;
use YATT_Helper::OIDC::Provider::Google;
use YATT_Helper::Google::Metadata;

Entity oidc => sub {
  my ($this) = @_;
  $CON->stash->{oidc} //= do {
    my $client_id = $this->entity_metadata('client_id');
    my $client_secret = $this->entity_metadata('client_secret');
    YATT_Helper::OIDC::Provider::Google->new(
      client_id => $client_id,
      client_secret => $client_secret,
      redirect_uri_base => $CON->mkurl('.'),
      redirect_location => 'callback',
    )
  };
};

Entity metadata => sub {
  my ($this, $name) = @_;
  $CON->stash->{metadata}{$name} //= do {
    my $meta = YATT_Helper::Google::Metadata->new(
      port_suffix => ":5000",
    );

    my $text = $meta->attribute($name);
    $text =~ s/\s*\z//;
    $text;
  };
};

