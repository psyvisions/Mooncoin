package Room::Controller::Tables;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Room::Controller::Tables - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub auto :Private {
  my ($self, $c) = @_;

  if (! $c->user) {
    $c->response->redirect(
      $c->uri_for(
        '/user/login',
        '',
        {
          'destination' => $c->uri_for( $c->action )
        }
      )
    );
  }

  1;
}


=head2 index

=cut

sub index_btc :Path('bitcoin') :Args(0) {
    my ( $self, $c ) = @_;

    my $tables_rs = $c->model("PokerNetwork::Pokertables")->search({
                                currency_serial => 1,
                                tourney_serial => 0,
                          },
                          {
                                order_by => {
                                  -desc => 'players',
                                },
                          });

    my $tables_structure;
    my $tables;
    my @popular_tables;


    while (my $rec = $tables_rs->next()) {
      my $game_seats = ($rec->seats > 2) ? $rec->seats .'-max' : 'Heads Up';
      my $game_limit = 'Limit';
      my $game_bets;

      # Determine betting limits
      $game_limit = 'No Limit' if $rec->betting_structure =~ /-no-limit$/;
      $game_limit = 'Pot Limit' if $rec->betting_structure =~ /-pot-limit$/;

      # Determine bets
      my @bets = split '-', $rec->betting_structure;
      $game_bets = $bets[0] .'/'. $bets[1];

      my $game_id = lc($game_seats .'-'. $rec->betting_structure .'-'. $rec->variant);
      $game_id =~ s/\s/-/g;
      $game_id =~ s/\./_/g;

      my $game_variant = $rec->variant;

      $tables_structure->{$game_variant}->{$game_seats}->{$game_limit}->{$game_bets}->{hash} = $game_id;
      $tables_structure->{$game_variant}->{$game_seats}->{$game_limit}->{$game_bets}->{players} += $rec->players;

      $tables->{$game_id}->{name} = $game_limit .' '. $game_seats .' Game ('. $game_bets .')';
      push @{$tables->{$game_id}->{tables}}, $rec;
      push @popular_tables, $rec unless $#popular_tables > 10;
    }

    $c->stash->{tables} = $tables;
    $c->stash->{tables_structure} = $tables_structure;
    $c->stash->{popular_tables} = \@popular_tables;
}

sub index_nmc :Path('namecoin') :Args(0) {
    my ( $self, $c ) = @_;

    my $tables_rs = $c->model("PokerNetwork::Pokertables")->search({
                                currency_serial => 2,
                                tourney_serial => 0,
                          },
                          {
                                order_by => {
                                  -desc => 'players',
                                },
                          });

    my $tables_structure;
    my $tables;
    my @popular_tables;


    while (my $rec = $tables_rs->next()) {
      my $game_seats = ($rec->seats > 2) ? $rec->seats .'-max' : 'Heads Up';
      my $game_limit = 'Limit';
      my $game_bets;

      # Determine betting limits
      $game_limit = 'No Limit' if $rec->betting_structure =~ /-no-limit$/;
      $game_limit = 'Pot Limit' if $rec->betting_structure =~ /-pot-limit$/;

      # Determine bets
      my @bets = split '-', $rec->betting_structure;
      $game_bets = $bets[0] .'/'. $bets[1];

      my $game_id = lc($game_seats .'-'. $rec->betting_structure .'-'. $rec->variant);
      $game_id =~ s/\s/-/g;
      $game_id =~ s/\./_/g;

      my $game_variant = $rec->variant;

      $tables_structure->{$game_variant}->{$game_seats}->{$game_limit}->{$game_bets}->{hash} = $game_id;
      $tables_structure->{$game_variant}->{$game_seats}->{$game_limit}->{$game_bets}->{players} += $rec->players;

      $tables->{$game_id}->{name} = $game_limit .' '. $game_seats .' Game ('. $game_bets .')';
      push @{$tables->{$game_id}->{tables}}, $rec;
      push @popular_tables, $rec unless $#popular_tables > 10;
    }

    $c->stash->{tables} = $tables;
    $c->stash->{tables_structure} = $tables_structure;
    $c->stash->{popular_tables} = \@popular_tables;
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

