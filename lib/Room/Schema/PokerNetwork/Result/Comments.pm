package Room::Schema::PokerNetwork::Result::Comments;

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
__PACKAGE__->table("comments");
__PACKAGE__->add_columns(
  "serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "bet_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "comment",
  { data_type => "TEXT", default_value => undef, is_nullable => 0 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("serial", "user_serial", "bet_serial");


__PACKAGE__->belongs_to(
  'user' => 'Room::Schema::PokerNetwork::Result::Users',
  { 'foreign.serial' => 'self.user_serial' }, { cascade_delete => 0 },
);

__PACKAGE__->has_one(
  'bet' => 'Room::Schema::PokerNetwork::Result::Bets',
  { 'foreign.serial' => 'self.bet_serial' }, { cascade_delete => 0 },
);

sub created_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->created_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T %Z');
  return $created;
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
