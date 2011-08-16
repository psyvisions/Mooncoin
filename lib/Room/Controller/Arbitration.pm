package Room::Controller::Arbitration;
use Moose;
use namespace::autoclean;
use DateTime;
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

Room::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub base :Chained :PathPart('user/arbitrator') :CaptureArgs(0) {
  my ($self, $c) = @_;
  if (!$c->user || $c->user->privilege != 3 ) {
    $c->detach( '/default' );
  }
}

sub index :Chained('base') :PathPart('') :Args(0) {
  my ($self, $c) = @_; 
   $c->stash->{arbs} = $c->model("PokerNetwork::Arb2section")->search({ 
   user_serial => $c->user->serial,
  }, { 
      order_by => { 
        -desc => 'created_at' 
      } 
  });
}

sub assignment :Chained('base') :CaptureArgs(1) {
  my ($self, $c, $id) = @_;
  $c->stash->{assignment} = $c->model("PokerNetwork::Arb2section")->find($id);
}

sub deposit :Chained('assignment') :Args(0) {
  my ($self, $c) = @_;
  my $user = $c->stash->{assignment}; 
  
  my $arb_balance = $c->user->balances->search({currency_serial => 1 })->first;
    
  $arb_balance->amount(
    $arb_balance->amount() - $c->stash->{assignment}->deposit_amount #covert from mooncoins
  );
  $arb_balance->update();
   
  $user->deposit(1);
  $user->update();
  $c->res->redirect(
    $c->uri_for('/user/arbitrator' )
  );
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

__PACKAGE__->meta->make_immutable;

