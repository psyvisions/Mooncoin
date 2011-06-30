package Finance::Namecoin::Address;

use Carp;
use Class::Accessor 'antlers';
use Finance::Namecoin;
use Scalar::Util qw[blessed];

our $VERSION = '0.002';

has address => (is => 'ro');
has api     => (is => 'rw');

sub new
{
	my ($class, $api, $address) = @_;
	
	unless (blessed($api) and $api->isa('Finance::Namecoin::API'))
	{
		$api = $api ? 
			Finance::Namecoin::API->new(endpoint=>"$api") : 
			Finance::Namecoin::API->new;
	}
	
	my $self = bless {
		api     => $api,
		address => $address,
		}, $class;
	
	return $self;
}

sub label
{
	my $self = shift;

	if (@_) # set
	{
		my $label = shift;
		$self->api->call('setlabel', $self->address, $label);
	}

	return $self->api->call('getlabel', $self->address);
}

sub received
{
	my ($self, $minconf) = @_;
	$minconf = 1 unless defined $minconf;
	return $self->api->call('getreceivedbyaddress', $self->address, $minconf);
}

1;

__END__

=head1 NAME

Finance::Namecoin::Address - a Namecoin address

=head1 SYNOPSIS

 use Finance::Namecoin;
 
 my $uri     = 'http://user:password@127.0.0.1:8332/';
 my $wallet  = Finance::Namecoin::Wallet->new($uri);
 
 foreach my $address ($wallet->addresses)
 {
   print $address->address . "\n";
   print $address->label . "\n";
   print $address->received . "\n\n";
 }

=head1 DESCRIPTION

This module is part of the high-level API for accessing a running
Namecoin instance.

=over 4

=item C<< new($endpoint, $string) >>

Constructor. $endpoint may be the JSON RPC endpoint URL, or may be a
Finance::Namecoin::API object; $string is an address string.

=item C<< address >>

Returns the address string.

=item C<< label >>

Get/set the address label.

=item C<< received($minconf) >>

Returns the total amount received via this address, with at least $minconf
confirmations. $minconf defaults to 1.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Finance::Namecoin>, L<Finance::Namecoin::Wallet>.

L<http://www.Namecoin.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

