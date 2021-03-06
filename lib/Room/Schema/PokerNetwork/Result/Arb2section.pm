package Room::Schema::PokerNetwork::Result::Arb2section;

use DateTime;
use Date::Manip;
use DateTime::Duration;
use Date::Parse;
use DateTime::Format::Strptime;

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
__PACKAGE__->table("arb2section");
__PACKAGE__->add_columns(
  "serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "rating",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "type",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "deposit",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "deposit_amount",
  { data_type => "FLOAT", default_value => undef, is_nullable => 0, size => 32 },
  "percentage",
  { data_type => "FLOAT", default_value => undef, is_nullable => 0, size => 32 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("serial");

__PACKAGE__->belongs_to(
  'user' => 'Room::Schema::PokerNetwork::Result::Users',
  { 'foreign.serial' => 'self.user_serial' }, { cascade_delete => 0 },
);

sub created_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->created_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T');
  return $created;
}

=head1 AUTHOR

mrmoon

=head1 LICENSE

mrmooncoin@gmail.com

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
