package Room::Schema::PokerNetwork::Result::Affiliates;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "FrozenColumns",
  "FilterColumn",
  "EncodedColumn",
  "Core",
);

=head1 NAME

Room::Schema::PokerNetwork::Result::Affiliates

=cut

__PACKAGE__->table("affiliates");

=head1 ACCESSORS

=head2 serial

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 modified

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 created

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 key

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 share

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 balance

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 escrow

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 prefix

  data_type: 'char'
  is_nullable: 1
  size: 3

=head2 users_count

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 users_rake

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 users_points

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=head2 companyname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

=head2 firstname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

=head2 lastname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

=head2 addr_street

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

=head2 addr_street2

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 255

=head2 addr_zip

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 addr_town

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 addr_state

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 128

=head2 addr_country

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 phone

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 url

  data_type: 'text'
  is_nullable: 1

=head2 service_url

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "serial",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "modified",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "created",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "key",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "share",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "balance",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "escrow",
  {
    data_type => "bigint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "prefix",
  { data_type => "char", is_nullable => 1, size => 3 },
  "users_count",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "users_rake",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "users_points",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "companyname",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "firstname",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "lastname",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "addr_street",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "addr_street2",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 255 },
  "addr_zip",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "addr_town",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "addr_state",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 128 },
  "addr_country",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "phone",
  { data_type => "varchar", default_value => "", is_nullable => 1, size => 64 },
  "url",
  { data_type => "text", is_nullable => 1 },
  "service_url",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("serial");

=head1 RELATIONS

=head2 users

Type: has_many

Related object: L<Room::Schema::PokerNetwork::Result::Users>

=cut

__PACKAGE__->has_many(
  "users",
  "Room::Schema::PokerNetwork::Result::Users",
  { "foreign.affiliate" => "self.serial" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-20 00:12:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xoHn+B5Rp2rpSbjjDrQFtQ


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
