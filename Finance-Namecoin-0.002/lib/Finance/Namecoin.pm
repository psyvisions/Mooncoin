package Finance::Namecoin;

use Finance::Namecoin::API;
use Finance::Namecoin::Wallet;
use Finance::Namecoin::Address;

our $VERSION = '0.002';

1;

__END__

=head1 NAME

Finance::Namecoin - manage a Namecoin instance

=head1 DESCRIPTION

Namecoin is a peer-to-peer network based digital currency.

This module provides high and low level APIs for managing a running
Namecoin instance over JSON-RPC.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Finance::Namecoin::API>,
L<Finance::Namecoin::Wallet>,
L<Finance::Namecoin::Address>.

L<http://www.Namecoin.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

