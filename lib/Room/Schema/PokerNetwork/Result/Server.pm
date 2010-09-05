package Room::Schema::PokerNetwork::Result::Server;

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
__PACKAGE__->table("server");
__PACKAGE__->add_columns(
  "version",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-27 00:26:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MckOtugrgqrhXxjD1vwwPg


# You can replace this text with custom content, and it will be preserved on regeneration
1;