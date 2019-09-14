use strict;

sub handle {
  (my MY $self, my ($ext, $con, $file)) = @_;
  my $this = $self->EntNS;

  my $has_session = $this->entity_session_state_exists;
  my $session; $session = $this->entity_psgix_session if $has_session;
  unless ($session and $session->{login}) {
    my $nx = $con->mkurl(undef, $con, local => 1);
    my $auth_url = $con->mkurl($this->entity_script_name. "/auth/", [nx => $nx], local => 1);
    # YATT::Lite::Util::dumpout($auth_url);
    $con->redirect($auth_url);
    return;
  }

  $self->SUPER::handle($ext, $con, $file);
}
