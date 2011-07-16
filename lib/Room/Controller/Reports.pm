package Room::Controller::Reports;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Room::Controller::Reports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;


  my $dt = DateTime->now;
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
 
  $c->stash->{bets} = $c->model("PokerNetwork::Reports")->search({}, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'deadline' 
      } 
  });
}

sub report_base : Chained('/') PathPart('report') CaptureArgs(1) {
     my ($self, $c, $id) = @_;


     my $report = $c->model('PokerNetwork::Reports')->find($id);

     if ( $report == undef ) {
         $c->stash( error_msg => "This item does not exist" );
     } else {
         $c->stash( report => $report );
     }
 }
 

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
