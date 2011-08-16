package Room::Controller::Admin::Staff;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head2 base

Base chain start 

=cut 

sub base :Chained :PathPart('admin') :CaptureArgs(0) {
  my ($self, $c) = @_;

  if (!$c->user || $c->user->privilege != 2) {
    $c->detach( '/default' );
  }
}

=head1 NAME

Room::Controller::Staff::Bets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub staff :Chained('base') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
 
  $c->stash->{arbs} = $c->model("PokerNetwork::Arb2section")->search({ 
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'created_at' 
      } 
  });
}

sub staff_base :Chained('base') :PathPart('arbitrator') :CaptureArgs(1) {
  my ($self, $c, $id) = @_;

  my $staff = $c->model("PokerNetwork::Arb2section")->find($id);

  if (! $staff) {
    $c->detach( '/default' );
  }

  $c->stash->{staff} = $staff;
}

sub assign_staff :Chained('base') :PathPart('staff/assignment') :FormConfig{
  my ($self, $c) = @_;

  $c->stash->{arbs} = $c->model("PokerNetwork::Users")->search({
  privilege => 3,
  }, { 
      order_by => { 
        -asc => 'serial' 
      } 
  });
  my $staff = $c->stash->{staff}; 
  my $form = $c->stash->{form};
  
  my $arb_serial = $form->params->{arb_userserial};
  my $type = $form->params->{arb_type};
  my $category = $form->params->{arb_category};
  my $deposit_amount = $form->params->{deposit};
  my $percentage = $form->params->{percent_amount};
  
  if ($form->submitted_and_valid) {
  # Create report
    my $arbitrator = $c->model('PokerNetwork::Arb2section')->create({
    user_serial => $arb_serial,
    type => $type,
    deposit => 0,
    category => $category,
    deposit_amount => $deposit_amount,
    percentage => $percentage,
    created_at => DateTime->now( time_zone => 'local' ),
  });
    push @{$c->flash->{messages}}, "Staff position created.";
  $c->res->redirect($c->uri_for('/admin/staff'));
  };
}

sub delete :Chained('staff_base') :Args(0) {
  my ($self, $c) = @_;
  my $user = $c->stash->{staff};
  
  my $uid = $c->model("PokerNetwork::Users")->find($user->user_serial);
 
 
  my $arb_balance = $uid->balances->search({currency_serial => 1 })->first;
  $arb_balance->amount(
    $arb_balance->amount() + $user->deposit_amount  #covert from mooncoins
  );
  $arb_balance->update();
  
  $user->delete;
  push @{$c->flash->{messages}}, "Staff position deleted.";
  $c->res->redirect(
    $c->uri_for('/admin/staff' )
  );
}

sub withdrawals :Chained('base') :Args(0) :Path('/admin/staff/withdrawals'){
  my ($self, $c) = @_;
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
  $c->stash->{withdrawals} = $c->model("PokerNetwork::Withdrawal")->search({
  processed => 0,
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'withdrawal_id' 
      } 
  });
}

sub edit :Chained('staff_base') :Args(0) :FormConfig{
  my ( $self, $c ) = @_;
  $c->stash->{arbs} = $c->model("PokerNetwork::Users")->search({
  privilege => 3,
  }, { 
      order_by => { 
        -asc => 'serial' 
      } 
  });
  my $form = $c->stash->{form};
  
  $form->get_field({name => 'arb_userserial'})->default(
    $c->stash->{staff}->user_serial
  );
  
  $form->get_field({name => 'percent_amount'})->default(
    $c->stash->{staff}->percentage
  );

  if ($form->submitted_and_valid) {
  
  $c->stash->{staff}->user_serial(
    $form->params->{arb_userserial}
  );
  
  $c->stash->{staff}->percentage(
    $form->params->{percent_amount}
  );
   
  $c->stash->{staff}->update();
  
  push @{$c->flash->{messages}}, "This arbitrator has been edited.";
  
  $c->res->redirect(
      $c->uri_for('/admin/staff/')
    );
  }
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

1;
