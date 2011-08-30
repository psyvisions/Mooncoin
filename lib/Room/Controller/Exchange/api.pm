package Room::Controller::Exchange::api;
use Moose;
use Date::Parse;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Room::Controller::Exchange::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path('/exchange/api') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
    
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	 $c->response->body('You need to specify the currency.');
	 return;
  }else{
    $other = $c->stash->{coin}->serial;
  }

}

sub ticker :Path('/exchange/api/ticker') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
    $other = 0;
	$c->response->body('You need to specify the currency.');
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  
  #Get last trade
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { cache => 1, rows => 25, order_by => { -desc => 'processed_at' }});
  
  $c->stash->{last_trade} = $c->stash->{recent_trades}->search(undef, { rows => 1 })->single;  
  
  # Get the value of everything bought in the last 7 days in btc
  $c->stash->{btc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 30 DAY)' },
  status => 0,
  -and => [{buy_currency => $primary},{sell_currency => $other}],
  }, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], cache => 1 });
  my $row_two = $c->stash->{btc_hold}->search(undef, { rows => 1 })->single; 
  $c->stash->{btc_total} = $row_two->get_column('total_amount');
  
  # Get the value of everything bought in the last 7days in nmc
  $c->stash->{nmc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 30 DAY)' },
  status => 0,
  -and => [{buy_currency => $other},{sell_currency => $primary}],
  }, {'+select' => [{ SUM => 'amount *  price' }],'+as' => [qw/total_amount/], cache => 1 });
  my $row_four = $c->stash->{nmc_hold}->search(undef, { rows => 1 })->single; 
  $c->stash->{nmc_total} = $row_four->get_column('total_amount');

  my $volume = $c->stash->{btc_total} + $c->stash->{nmc_total};
  
  my $btc7d = $c->stash->{btc_hold}->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 1 DAY)' },})->get_column('price');
  my $nmc7d = $c->stash->{nmc_hold}->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 1 DAY)' },})->get_column('1 / price');  

  my $nmc7dmax = $nmc7d->max;
  my $btc7dmax = $btc7d->max;

  my $high;
  my $low;
  if( $btc7dmax > $nmc7dmax ){
  $high = $btc7dmax;
  }else{$high = $nmc7dmax;}
  
  my $nmc7dmin = $nmc7d->min;
  my $btc7dmin = $btc7d->min;;
    
  if( $btc7dmin < $nmc7dmin ){
  $low = $btc7dmin;
  }else{$low = $nmc7dmin;}
  
  my $average = (( $low + $high ) / 2);
  
  my $last_trade;
  if( $c->stash->{last_trade}->sell_currency == 1 ){ 
  $last_trade = 1 / $c->stash->{last_trade}->price;
  }else{
  $last_trade = $c->stash->{last_trade}->price;
  }
  
  $c->response->body('{"ticker":{"high":' . sprintf('%.6f',$high) . ',"low":' . sprintf('%.6f',$low) . '."vol":' . sprintf('%.6f',$volume) . ',"last":' . sprintf('%.6f',$last_trade) . ',"average":' . sprintf('%.6f',$average) . '}}' );
}

sub order_book :Path('/exchange/api/ob') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->response->body('You need to specify the currency.');
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  
  $c->stash->{buy_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $other},{sell_currency => $primary}],
  }, { cache => 1, order_by => { -asc => 'price' } });
  
  $c->stash->{sell_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $primary},{sell_currency => $other}],
  }, { cache => 1, order_by => { -asc => 'price' } });
  
  my $bid_output;

  while ( my $bid = $c->stash->{buy_nmc}->next ){
    $bid_output = $bid_output . '[' . sprintf('%.6f', ( 1 / $bid->price )) . ',' . sprintf('%.6f', ( $bid->balance * $bid->price ))  . '],';  
  }  
  
  my $ask_output;
  while ( my $ask = $c->stash->{sell_nmc}->next ){
    $ask_output = $ask_output . '[' . $ask->price . ',' . $ask->balance . '],';  
  }   
  
  $c->response->body('{"asks":[' . substr($bid_output, 0, -1) . '],"bids":[' . substr($ask_output, 0, -1) . ']}' );
  
}


sub last_10 :Path('/exchange/api/last10') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->response->body('You need to specify the currency.');
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { rows => 10, order_by => { -desc => 'processed_at' }});
  
  my $recent_output;
  my $type;
  my $b_amount;
  while ( my $rt = $c->stash->{recent_trades}->next ){
  	if($other == $rt->sell_currency ){ $type = '"buy"' }else{ $type = '"sell"' } 
  	if($rt->bought == undef ){ $b_amount = $rt->amount }else{ $b_amount = $rt->bought }
    $recent_output = $recent_output . '{"date":"' .  str2time($rt->processed_at) . '","type":' . $type . ',"price":' . sprintf('%.6f',$rt->price) . ',"amount":' . $b_amount . ',"id":"' . $rt->serial . '"},';  
  }
  
  $c->response->body('[' . substr($recent_output, 0 , -1) .  ']');
}


sub last_12h :Path('/exchange/api/last12h') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->response->body('You need to specify the currency.');
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 12 HOUR)' },
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { order_by => { -desc => 'processed_at' }});
  
  my $recent_output;
  my $type;
  my $b_amount;
  while ( my $rt = $c->stash->{recent_trades}->next ){
  	if($other == $rt->sell_currency ){ $type = '"buy"' }else{ $type = '"sell"' } 
  	if($rt->bought == undef ){ $b_amount = $rt->amount }else{ $b_amount = $rt->bought }
    $recent_output = $recent_output . '{"date":"' .  str2time($rt->processed_at) . '","type":' . $type . ',"price":' . sprintf('%.6f',$rt->price) . ',"amount":' . $b_amount . ',"id":"' . $rt->serial . '"},';  
  }
  
  $c->response->body('[' . substr($recent_output, 0 , -1) .  ']');
}


sub price :Path('/exchange/api/price') CaptureArgs(1){
  my ( $self, $c, $coin ) = @_;
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->response->body('You need to specify the currency.');
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  
  my $best_bid = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $other},{sell_currency => $primary}],
  }, { order_by => { -asc => 'price' } })->first;
  
  my $best_ask = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $primary},{sell_currency => $other}],
  }, { order_by => { -asc => 'price' } })->first; 
  
  # Get the value of everything bought in the last 7 days in btc
  $c->stash->{btc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  status => 0,
  -and => [{buy_currency => $primary},{sell_currency => $other}],
  }, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], cache => 1 });
  my $row_two = $c->stash->{btc_hold}->search(undef, { rows => 1 })->single; 
  $c->stash->{btc_total} = $row_two->get_column('total_amount');
  
  # Get the value of everything bought in the last 7days in nmc
  $c->stash->{nmc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  status => 0,
  -and => [{buy_currency => $other},{sell_currency => $primary}],
  }, {'+select' => [{ SUM => 'amount *  price' }],'+as' => [qw/total_amount/], cache => 1 });
  my $row_four = $c->stash->{nmc_hold}->search(undef, { rows => 1 })->single; 
  $c->stash->{nmc_total} = $row_four->get_column('total_amount');

  my $volume = $c->stash->{btc_total} + $c->stash->{nmc_total};
  
  my $btc7d = $c->stash->{btc_hold}->get_column('price');
  my $nmc7d = $c->stash->{nmc_hold}->get_column('1 / price');  

  my $nmc7dmax = $nmc7d->max;
  my $btc7dmax = $btc7d->max;

  my $high;
  my $low;
  if( $btc7dmax > $nmc7dmax ){
  $high = $btc7dmax;
  }else{$high = $nmc7dmax;}
  
  my $nmc7dmin = $nmc7d->min;
  my $btc7dmin = $btc7d->min;;
    
  if( $btc7dmin < $nmc7dmin ){
  $low = $btc7dmin;
  }else{$low = $nmc7dmin;}
  
  $c->response->body('var solidcoin_buyprice = ' . sprintf('%.6f',( 1 / $best_bid->price )) .  '; var solidcoin_sellprice = ' . sprintf('%.6f',$best_ask->price) . '; var solidcoin_highprice = ' . sprintf('%.6f',$high) . '; var solidcoin_lowprice = ' . sprintf('%.6f',$low) . ';');
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
