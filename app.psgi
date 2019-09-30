# -*- perl -*-
use strict;
use warnings;
sub MY () {__PACKAGE__}; # omissible

use FindBin;
use lib "$FindBin::Bin/lib"
  # , glob("$FindBin::Bin/extlib/*/lib")
  , "$FindBin::Bin/local/lib/perl5";

use Plack::Builder;

use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity *CON/;
use YATT::Lite::WebMVC0::Partial::Session2 -as_base;

use YATT_Addon::Google -entns;

use Plack::Session::State::Cookie;

{
  my $app_root = $FindBin::Bin;
  my $config_dir = "$app_root.config.d";
  my $metadata = Metadata->instance(mock_dir => "$config_dir/metadata");

  my $session_store = do {
    require CHI;
    [Cache => cache => CHI->new(driver => 'File', root_dir => "$app_root/var/db")]
  };

  unless (-w (my $dir = $session_store->[-1]->root_dir."/Default")) {
    Carp::croak "Session store is not writable!: $dir";
  }

  my MY $site = MY->load_factory_for_psgi(
    $0,
    doc_root => "$app_root/public",
    use_sibling_config_dir => 1,
    # config_dir => "$app_root.config.d",
    session_store => $session_store,
  );

  $site->examine_site_config;

  Entity config_dir => sub {
    my ($this) = @_;
    $site->cget('config_dir');
  };

  Entity has_config_path => sub {
    my ($this, $path) = @_;
    -e ($this->entity_config_dir . "/$path");
  };

  if (-d (my $staticDir = "$app_root/static")) {
    $site->mount_static("/static" => $staticDir);
  }

  # Define entities here.
  Entity backend => sub {
    my ($this) = @_;
    $CON->stash->{backend} //= $site->create_backend;
  };


  use YATT_Helper::EmailRegexp qw/$EMAIL_PATTERN/;

  Entity email_pattern => sub {
    my ($this) = @_;
    \ qq{"\\s*$EMAIL_PATTERN\\s*"};
  };

  # To use yatt.lint, you must wrap Plack::Builder result with $site->wrapped_by.
  # Without this, yatt.lint can't find proper $yatt from anonymous sub.

  return $site->wrapped_by(builder {
    enable "SimpleLogger", level => "warn";

    $site->to_app;
  });
}

sub create_backend {
  my ($site, @args) = @_;
  require MyBackend;
  my $cfgFile = $site->cget('config_dir') . "/backend.yml";
  if (-r $cfgFile) {
    MyBackend->cli_create_from_file($cfgFile, @args);
  } else {
    MyBackend->new(@args);
  }
}
