use strict;

sub declare_site_config_entity ($;$) {
  my ($name, $default) = @_;
  Entity $name => sub {
    shift->site_config($name => $default);
  };
}

declare_site_config_entity(myorg_name => 'ACME Company');
declare_site_config_entity(myorg_domain => 'example.com');
