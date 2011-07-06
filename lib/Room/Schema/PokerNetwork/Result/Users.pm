package Room::Schema::PokerNetwork::Result::Users;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "FrozenColumns",
  "FilterColumn",
  "EncodedColumn",
  "Core",
);
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "created",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "affiliate",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 10 },
  "skin_url",
  {
    data_type => "VARCHAR",
    default_value => "random",
    is_nullable => 1,
    size => 255,
  },
  "skin_outfit",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "skin_image",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "skin_image_type",
  {
    data_type => "VARCHAR",
    default_value => "image/png",
    is_nullable => 1,
    size => 32,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "privilege",
  { data_type => "INT", default_value => 1, is_nullable => 1, size => 11 },
  "locale",
  {
    data_type => "VARCHAR",
    default_value => "en_US",
    is_nullable => 1,
    size => 32,
  },
  "rating",
  { data_type => "INT", default_value => 1000, is_nullable => 1, size => 11 },
  "future_rating",
  { data_type => "FLOAT", default_value => 1000, is_nullable => 1, size => 32 },
  "games_count",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 11 },
  "data",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
);
__PACKAGE__->set_primary_key("serial");
__PACKAGE__->add_unique_constraint("email_idx", ["email"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-27 11:47:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vEdFh5CdQczNMcB+q/BW4A

use JSON::XS;
use Hash::AsObject;

__PACKAGE__->add_columns(
  'password' => {
    data_type           => 'VARCHAR',
    size                => 40,
    encode_column       => 1,
    encode_class        => 'Digest',
    encode_check_method => 'check_password',
    encode_args         => {
                             algorithm    => 'SHA-1',
                             format       => 'hex',
                           },
  },
);

__PACKAGE__->inflate_column(
    'created',
    {
      inflate => sub {
        DateTime->from_epoch(
          epoch => shift
        );
      },
      deflate => sub {
        shift->epoch;
      },
    },
);

__PACKAGE__->add_json_columns(
  data => qw/bitcoin_address bitcoins_received namecoin_address namecoins_received request_password hide_gravatar emergency_address emergency_nmc_address/,
);

__PACKAGE__->has_many(
  'balances' => 'Room::Schema::PokerNetwork::Result::User2money',
  { 'foreign.user_serial' => 'self.serial' },
);

__PACKAGE__->has_many(
  'userhands' => 'Room::Schema::PokerNetwork::Result::User2hand',
  { 'foreign.user_serial' => 'self.serial' },
);
__PACKAGE__->many_to_many(
  hands => 'userhands', 'hand'
);

__PACKAGE__->has_many(
  'deposits' => 'Room::Schema::PokerNetwork::Result::Deposits',
  { 'foreign.user_serial' => 'self.serial' },
);

__PACKAGE__->has_many(
  'withdrawals' => 'Room::Schema::PokerNetwork::Result::Withdrawal',
  { 'foreign.user_serial' => 'self.serial' },
);
__PACKAGE__->has_many(
  'bets' => 'Room::Schema::PokerNetwork::Result::Bets',
  { 'foreign.user_serial' => 'self.serial' },
);

sub get_bitcoin_deposit_address {
  my ($self) = @_;

  if (! $self->data->bitcoin_address) {
    
  }

  return $self->data->bitcoin_address;
}

sub get_namecoin_deposit_address {
  my ($self) = @_;

  if (! $self->data->namecoin_address) {
    
  }

  return $self->data->namecoin_address;
}

=head1 AUTHOR

Pavel Karoukin

=head1 LICENSE

Copyright (C) 2010 Pavel A. Karoukin <pavel@yepcorp.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
