package YATT_Addon::Google;
use strict;
use warnings;

use YATT::Lite::Util::AsBase qw/-as_base import/;
use YATT::Lite qw/Entity *CON/;

use YATT_Helper::OIDC::Provider::Google;
use YATT_Helper::Google::Metadata [as => 'Metadata'];

# -entns を指定すると呼ばれて、
# ${callpack}::EntNS の ISA に
# ${mypack}::EntNS を入れる
sub _import_entns {
  my ($pack, $callpack) = @_;
  my $sym = YATT::Lite::Util::globref($callpack."::EntNS", 'ISA');
  my $isa;
  unless ($isa = *{$sym}{ARRAY}) {
    *$sym = $isa = [];
  }
  push @$isa, $pack."::EntNS";
}

Entity metadata => sub {
  my ($this, $name) = @_;
  $CON->stash->{metadata}{$name} //= do {
    my $text = Metadata->instance->attribute($name);
    $text =~ s/\s*\z//;
    $text;
  };
};

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


1;
