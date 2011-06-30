package Catalyst::Helper::Model::Namecoin;

use strict;
use warnings;

our $VERSION = '0.02';


sub mk_compclass {
  my ($self, $helper, $uri) = @_;

  $helper->{uri} = $uri;

  $helper->render_file('Namecoin', $helper->{file});
}

1;

=head1 NAME

Catalyst::Helper::Model::Namecoin - Helper class for Namecoin models 

=head1 SYNOPSIS

  ./script/myapp_create.pl model NamecoinClient Namecoin

=head1 DESCRIPTION

A Helper for creating models to interface with Namecoin Server

=head1 SEE ALSO

L<https://github.com/hippich/Catalyst--Model--Namecoin>, L<https://www.Namecoin.org>, L<Finance::Namecoin>, L<Catalyst>

=head1 AUTHOR

Pavel Karoukin
E<lt>pavel@yepcorp.comE<gt>
http://www.yepcorp.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pavel Karoukin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

__DATA__
=begin pod_to_ignore

__Namecoin__
package [% class %];

use strict;
use warnings;

use base qw/ Catalyst::Model::Namecoin /;

__PACKAGE__->config(
  uri => '[% uri %]',
);

=head1 NAME

[% class %] - Namecoin Server Model Class

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION 

Namecoin Server Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;
