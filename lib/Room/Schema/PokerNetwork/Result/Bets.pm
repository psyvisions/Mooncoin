package Room::Schema::PokerNetwork::Result::Bets;

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
__PACKAGE__->table("bets");
__PACKAGE__->add_columns(
  "serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "type",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "side_one",
  { data_type => "TEXT", default_value => undef, is_nullable => 0, size => 100 },
  "side_two",
  { data_type => "TEXT", default_value => undef, is_nullable => 0, size => 100 },
  "conditions",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "currency_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "challenger_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "deadline",
  { data_type => "datetime", default_value => undef, is_nullable => 0 },
  "user_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
   "report_serial",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "amount",
  { data_type => "FLOAT", default_value => undef, is_nullable => 0, size => 32 },
  "user_status",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11  },
  "challenger_status",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11  },
    "active",
  { data_type => "INT", default_value => undef, is_nullable => 0 , size => 11 },
    "category",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "title",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 0, size => 100 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 600,
  },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
    "challenged_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
  "u_status_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
   "c_status_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
     "finished_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("serial");

__PACKAGE__->belongs_to(
  'currency' => 'Room::Schema::PokerNetwork::Result::Currencies',
  { 'foreign.serial' => 'self.currency_serial' }, { cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  'user' => 'Room::Schema::PokerNetwork::Result::Users',
  { 'foreign.serial' => 'self.user_serial' }, { cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  'challenger' => 'Room::Schema::PokerNetwork::Result::Users',
  { 'foreign.serial' => 'self.challenger_serial' }, { cascade_delete => 0 },
);
#reports is kinda messed up but wont fix it right now until I can fix everything
__PACKAGE__->has_many(
  'report' => 'Room::Schema::PokerNetwork::Result::Reports',
  { 'foreign.serial' => 'self.report_serial' }, { cascade_delete => 0 },
);

__PACKAGE__->has_many(
  'comments' => 'Room::Schema::PokerNetwork::Result::Comments',
  { 'foreign.bet_serial' => 'self.serial' }, { cascade_delete => 0 },
);

__PACKAGE__->has_many(
  'userbets' => 'Room::Schema::PokerNetwork::Result::User2bet',
  { 'foreign.bet_serial' => 'self.serial' }, { cascade_delete => 0 },
);

sub get_total {
  my ($self) = @_;
  ## Total bet amount
     my $holder = $self->userbets->search({ 
     bet_serial => $self->serial,}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $total_holder = $holder->first;

     my $value = $total_holder->get_column('total_amount');
	 
	 if($value == undef){$value = 0;}	
		
  return $value;
}

sub get_ratio {
  my ($self) = @_;
  
     ## Total side one amount
     my $userbets_s_one_total = $self->userbets->search({ 
     bet_serial => $self->serial, side => 1}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_one = $userbets_s_one_total->first;

     my $total_side_one = $row_one->get_column('total_amount');
     ## Total side two amount
     my $userbets_s_two_total = $self->userbets->search({ 
     bet_serial => $self->serial, side => 2}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_two = $userbets_s_two_total->first;

     my $total_side_two = $row_two->get_column('total_amount');  
     ## RATIO
     my $ratio;
	 my $h_side;
     if( $total_side_one > $total_side_two and $total_side_two != undef ){
      $ratio = $total_side_one / $total_side_two;
      $h_side = 1;
      }
     elsif( $total_side_one < $total_side_two and $total_side_one != undef ){
      $ratio = $total_side_two / $total_side_one; 
      $h_side = 2;
    }
     else{ $ratio = 1;}
 
     return $ratio;
  
}

sub get_h_side {
  my ($self) = @_;
  
       ## Total side one amount
     my $userbets_s_one_total = $self->userbets->search({ 
     bet_serial => $self->serial, side => 1}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_one = $userbets_s_one_total->first;

     my $total_side_one = $row_one->get_column('total_amount');
     ## Total side two amount
     my $userbets_s_two_total = $self->userbets->search({ 
     bet_serial => $self->serial, side => 2}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_two = $userbets_s_two_total->first;

     my $total_side_two = $row_two->get_column('total_amount');  
     ## RATIO
     my $ratio;
	 my $h_side;
     if( $total_side_one > $total_side_two and $total_side_two != undef ){
      $ratio = $total_side_one / $total_side_two;
      $h_side = 1;
      }
     elsif( $total_side_one < $total_side_two and $total_side_one != undef ){
      $ratio = $total_side_two / $total_side_one; 
      $h_side = 2;
    }
    else{$h_side = 0;}
    
    return $h_side;    
}

sub get_timeleft{
  my ($self) = @_;
  my $bet_stop = DateTime::Duration->new(minutes => 0,);
  my $fmt = '%Y-%m-%dT%H:%M:%S';
  my $parser = DateTime::Format::Strptime->new(pattern => $fmt);
  my $diff = DateTime::Duration->new(minutes => 0,);
  my $dt1 = $parser->parse_datetime($self->deadline);
  my $dt2 = $parser->parse_datetime(DateTime->now( time_zone => 'local' ));
   
  my $diff1 = DateTime::Duration->new( $dt1 - $dt2 );
  
  if($diff1->is_positive == 1 and $diff1->minutes > 30){  
  $bet_stop = DateTime::Duration->new(minutes => 30, seconds => 0,);
  $diff = $diff1 - $bet_stop; 
  }
  
  if ($diff->is_negative == 1 ){
  $diff = $diff - $diff;
  }

  return $diff;
}

sub deadline_passed{
  my ($self) = @_;
  my $bet_stop = DateTime::Duration->new(minutes => 0,);
  my $diff = DateTime::Duration->new(minutes => 0,);
  my $passed = 0;
  if( $self->type == 1){
  my $fmt = '%Y-%m-%dT%H:%M:%S';
  my $parser = DateTime::Format::Strptime->new(pattern => $fmt);

  my $dt1 = $parser->parse_datetime($self->deadline);
  my $dt2 = $parser->parse_datetime(DateTime->now( time_zone => 'local' ));

  my $diff1 = DateTime::Duration->new( $dt1 - $dt2 );
  
  ### FIX TIMER - start bet that happens soon and it has + 30 minutes on timer
  if($diff1->is_positive == 1 and $diff1->minutes > 30){  
  $bet_stop = DateTime::Duration->new(minutes => 30,);
  $diff = $diff1 - $bet_stop; 
  }
    
  if ($diff->is_negative == 1 ){
  $passed = 1;
  }
  elsif ($diff->is_positive == 1 ){
  $passed = 0;
  }else{
  $passed = 1;
  }
  return $passed;
}elsif ( $self->type == 2){ 

  if( $self->challenger_serial != undef){
  my $timehold = $self->challenged_at;
  
  if ( $self->challenger_status == undef and $self->user_status != undef ){
  $timehold = $self->u_status_at;
  }elsif($self->user_status == undef and $self->challenger_status != undef ){
  $timehold = $self->c_status_at;
  }
  
  my $fmt = '%Y-%m-%dT%H:%M:%S';
  my $parser = DateTime::Format::Strptime->new(pattern => $fmt);

  my $dt1 = $parser->parse_datetime($timehold);
  my $dt2 = $parser->parse_datetime(DateTime->now( time_zone => 'local' ));

  my $diff = DateTime::Duration->new( years => 0, months => 0, days => 0, hours => 0, minutes => 0, seconds => 0);
  my $seven = DateTime::Duration->new(days => 7,);

  my $u_deadline =  $dt1 + $seven ;
  $diff = $dt2 - $u_deadline;
      my $passed;
  if ($diff->is_negative == 1 ){
  $passed = 1;
  }
  elsif ($diff->is_positive == 1 ){
  $passed = 0;
  }else{
  $passed = 1;
  }
  return $passed;
  }

}
}

sub get_timeleft_update{
  my ($self) = @_;
  
  
   if( $self->challenger_serial != undef){
  my $timehold = $self->challenged_at;
  if ( $self->challenger_status == undef and $self->user_status != undef ){
  $timehold = $self->u_status_at;
  }elsif($self->user_status == undef and $self->challenger_status != undef ){
  $timehold = $self->c_status_at;
  }
  
  
  my $fmt = '%Y-%m-%dT%H:%M:%S';
  my $parser = DateTime::Format::Strptime->new(pattern => $fmt);

  my $dt1 = $parser->parse_datetime($timehold);
  my $dt2 = $parser->parse_datetime(DateTime->now( time_zone => 'local' ));

  my $diff = DateTime::Duration->new( years => 0, months => 0, days => 0, hours => 0, minutes => 0, seconds => 0);
  my $seven = DateTime::Duration->new(days => 7,);

  my $u_deadline =  $dt1 + $seven ;
  $diff = $dt2 - $u_deadline;
  
  if ($diff->is_negative == 0 ){
  $diff = DateTime::Duration->new( years => 0, months => 0, days => 0, hours => 0, minutes => 0, seconds => 0);
  }
  
  return $diff;
   }else{ my $diff = 0; return $diff;}
}

sub event_time_readable{
  my ($self) = @_;
  my $strdate1 = str2time($self->deadline);
  my $time1 = UnixDate(ParseDate("epoch $strdate1"), '%F %T');
  return $time1;
}

sub time_now_readable{
  my ($self) = @_;
  my $strdate1 = str2time(DateTime->now( time_zone => 'local' ));
  my $time1 = UnixDate(ParseDate("epoch $strdate1"), '%F %T %Z');
  return $time1;
}

sub created_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->created_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T');
  return $created;
}

sub challenged_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->challenged_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T');
  return $created;
}

sub u_status_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->u_status_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T');
  return $created;
}

sub c_status_time_readable{
  my ($self) = @_;
  my $crstr = str2time($self->c_status_at);
  my $created = UnixDate(ParseDate("epoch $crstr"), '%F %T');
  return $created;
}

sub who_won{
  my ($self) = @_;
  my $value = undef;
  if($self->user_status != undef and $self->challenger_status != undef ){
  if( $self->user_status == '1' and $self->challenger_status == '2' ){
  $value = $self->user_serial;
  }
  elsif($self->user_status == '2' and $self->challenger_status == '1' ){
  $value = $self->challenger_serial;
  }
  elsif($self->user_status == '3' and $self->challenger_status == '3'){
  $value = 0;
  }
  else{
  $value = 'conflict';
  }
  }

  return $value;

}

# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-27 11:47:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TfffnTDxPNXCprfGWMEtFw


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
