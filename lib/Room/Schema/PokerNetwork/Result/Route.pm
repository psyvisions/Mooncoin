package Room::Schema::PokerNetwork::Result::Route;

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

Room::Schema::PokerNetwork::Result::Route

=cut

__PACKAGE__->table("route");

=head1 ACCESSORS

=head2 table_serial

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 tourney_serial

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 modified

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 resthost_serial

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "table_serial",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "tourney_serial",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "modified",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "resthost_serial",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("table_serial", "tourney_serial");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-20 00:04:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3G/tm8K5EfJRcgjl9ADqdQ


# You can replace this text with custom content, and it will be preserved on regeneration

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
