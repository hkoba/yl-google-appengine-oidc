package YATT_Helper::EmailRegexp;
use MOP4Import::Declare -as_base;

our $EMAIL_PATTERN = q{[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+};

sub email_localpart {
  (my MY $self, my $email) = @_;
  $email =~ s/[\+\@].*//;
  $email;
}

1;
