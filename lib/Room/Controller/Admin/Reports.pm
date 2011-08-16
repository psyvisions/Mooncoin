package Room::Controller::Admin::Reports;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

sub base :Chained :PathPart('admin') :CaptureArgs(0) {
  my ($self, $c) = @_;
    if (!$c->user || $c->user->privilege != 2) {
    $c->detach( '/default' );
  }
}

=head1 NAME

Room::Controller::Admin::Reports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

## Reporting system for bets ##

sub report_base :Chained('base') :PathPart('report') :CaptureArgs(1) {
  my ($self, $c, $id) = @_;

  my $report = $c->model("PokerNetwork::Reports")->find($id);

  if (! $report) {
    $c->detach( '/default' );
  }

  $c->stash->{report} = $report;
}

sub reports :Chained('base') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{reports} = $c->model("PokerNetwork::Reports")->search({}, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub report :Chained('report_base') :PathPart('view') :Args(0) {
  my ($self, $c) = @_;
  
  my $bet = $c->model('PokerNetwork::Bets')->find($c->stash->{report}->bet_serial);
  
  if($bet == undef){ 
     $c->stash->{report}->delete;
   }
     $c->stash->{cur_user_bets} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial,}, {order_by => { 
       -desc => 'created_at' } });
}

sub report_delete :Chained('report_base') :PathPart('delete') :Args(0) {
  my ($self, $c) = @_;
  my $dd = $c->stash->{report};
  $dd->delete;
  push @{$c->flash->{messages}}, "This report has been deleted and the bet is still on.";
  $c->res->redirect(
      $c->uri_for('/admin/reports')
    );
}

sub report_cancel :Chained('report_base') :PathPart('cancel') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->model('PokerNetwork::Bets')->find($c->stash->{report}->bet_serial);
  my $username;
  my $userbet;
  my $fees;
  my $amount_due;
  
  if( $bet->type == 2 ){
  my $amount = $bet->amount;
  my $c_balance = $bet->user->balances->search({currency_serial => $bet->currency_serial })->first;
  
  if (! $c_balance) {
    $c_balance = $bet->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
      my $fees = $amount * 0.01;
    my $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();

  my $u_balance = $bet->challenger->balances->search({currency_serial => $bet->currency_serial })->first;
   if (! $u_balance) {
    $u_balance = $bet->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $u_balance->amount(0);
    $u_balance->update();
  }

    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;

    $u_balance->amount(
      $u_balance->amount() + ( $amount_due / 100 )
    );
    $u_balance->update();
 
  }elsif( $bet->type == 1 ){ 
   foreach $userbet($bet->userbets) { 
    my $amount = $userbet->amount;
    my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;
   
    if (! $balance) {
      $balance = $userbet->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
      $balance->amount(0);
      $balance->update();
    }
    
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();

    } 
  }
  
  my $dd = $c->stash->{report};
  $dd->delete;
  $bet->delete;
 
  push @{$c->flash->{messages}}, "The bet has been cancelled and the coins have been returned." ;
  
  $c->res->redirect(
      $c->uri_for('/admin/reports')
    );     

}

sub report_freeze :Chained('report_base') :PathPart('freeze') :Args(0) {
  my ($self, $c) = @_;

  my $bet = $c->model('PokerNetwork::Bets')->find($c->stash->{report}->bet_serial);
  
  my $dd = $c->stash->{report};
  $dd->delete;
  #active 1 is frozen
  $bet->active('1');
  $bet->finished_at(DateTime->now);
  $bet->update();
  
  push @{$c->flash->{messages}}, "This bet has been cancelled and a the funds have been freezed.";
  
  $c->res->redirect(
      $c->uri_for('/admin/reports')
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

1;
