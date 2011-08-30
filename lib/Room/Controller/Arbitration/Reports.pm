package Room::Controller::Arbitration::Reports;
use Moose;
use namespace::autoclean;
use DateTime;
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

sub base :Chained :PathPart('user/arbitrator') :CaptureArgs(0) {
  my ($self, $c) = @_;
    if (!$c->user || $c->user->privilege != 3 ) {
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

sub notify :Chained('report_base') :PathPart('notify') :Args(0) {
  my ($self, $c) = @_;
  my $report = $c->stash->{report};
  my $bet = $c->model('PokerNetwork::Bets')->find($c->stash->{report}->bet_serial);
  
  my $message = "Report Message: ". $report->description;

    $c->log->debug($message);

    $c->email(
        header => [
            From    => $c->config->{site_email},
            To      => $c->config->{site_email},
            Subject => 'Arbitrator Report: ' . $report->title,
        ],
        body => $message,
    );  
        
    push @{$c->stash->{messages}}, "You have reported an issue regarding this bet.";
    $c->res->redirect($c->uri_for('/bet/' . $bet->serial . '/view'));
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

__PACKAGE__->meta->make_immutable;

1;