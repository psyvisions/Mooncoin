package Room::Schema::PokerNetwork::Result::User2table;

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
__PACKAGE__->table("user2table");
__PACKAGE__->add_columns(
  "user_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "table_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "money",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "bet",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);

__PACKAGE__->set_primary_key("user_serial", "table_serial");

__PACKAGE__->has_relationship(
  'table' => 'Room::Schema::PokerNetwork::Result::pokertables', {'foreign.serial' => 'self.table_serial', "foreign.currency" => 2,},
);

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-27 11:47:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qax8lygssf9jjVXTrdjbZw


__PACKAGE__->belongs_to(
  user => 'Room::Schema::PokerNetwork::Result::Users',
  { serial => 'user_serial' }, { cascade_delete => 0 }
);

__PACKAGE__->belongs_to(
  pokertable => 'Room::Schema::PokerNetwork::Result::Pokertables',
  { serial => 'table_serial' }
);

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
