package Room::Controller::Exchange;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use String::Random;
use POSIX;
use DateTime;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

Room::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path CaptureArgs(1){
  my ( $self, $c, $coin) = @_;
  my $bitcoin = 1;
  my $other = 2;
  $c->stash->{coin} = 2;
  $c->stash->{symbol} = 'NMC';
  if($coin eq 'solidcoin'){
  $other = 3;
  $c->stash->{coin} = 3;
  $c->stash->{symbol} = 'SLC';
  }

  $c->stash->{buy_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  }, { order_by => { -asc => 'price' } });
  
  $c->stash->{sell_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1, 
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  }, {  order_by => { -asc => 'price' } });
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, {rows => 25, order_by => { -desc => 'processed_at' }});
  
  $c->stash->{last_trade} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { order_by => { -desc => 'processed_at' }})->first;  
  
  $c->stash->{rt_graph} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, {rows => 50, order_by => { -desc => 'processed_at'}});

  $c->stash->{ask_buy} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  }, { order_by => { -asc => 'price' }})->first;   
  
  $c->stash->{ask_sell} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  }, { order_by => { -asc => 'price' }})->first;  
  
  # Get the value of everything bought in the last 24 hours in btc
  $c->stash->{btc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 24 DAY)' },
  status => 0,
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  }, {'+select' => [{ SUM => ('amount') }],'+as' => [qw/total_amount/], });
  my $row_one = $c->stash->{btc_hold}->first;
  $c->stash->{btc_total} = $row_one->get_column('total_amount');

  $c->stash->{btc_nmc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  created_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  status => 0,
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  }, {'+select' => [{ SUM => 'amount * price' }],'+as' => [qw/total_amount/], });
  my $row_two = $c->stash->{btc_nmc_hold}->first;
  $c->stash->{btc_nmc_total} = $row_two->get_column('total_amount');

  $c->stash->{btc_7dvolume} = $c->stash->{btc_nmc_total} + $c->stash->{btc_total};
  my $btc7d = $c->stash->{btc_7dvolume};
  # Get the value of everything bought in the last 24 hours in nmc
  $c->stash->{nmc_btc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 24 DAY)' },
  status => 0,
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  }, {'+select' => [{ SUM => ('amount * price') }],'+as' => [qw/total_amount/], });
  my $row_three = $c->stash->{nmc_btc_hold}->first;
  $c->stash->{nmc_btc_total} = $row_three->get_column('total_amount');

  $c->stash->{nmc_hold} = $c->model("PokerNetwork::Trades")->search({ 
  created_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  status => 0,
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  }, {'+select' => [{ SUM => 'amount * price' }],'+as' => [qw/total_amount/], });
  my $row_four = $c->stash->{nmc_hold}->first;
  $c->stash->{nmc_total} = $row_four->get_column('total_amount');

  $c->stash->{nmc_7dvolume} = $c->stash->{nmc_total} + $c->stash->{nmc_btc_total};
  my $nmc7d = $c->stash->{nmc_7dvolume};  
  
  ##high low avg
  $c->stash->{btc_last24} = $c->model("PokerNetwork::Trades")->search({
  status => 0, 
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  }, { order_by => { -desc => 'processed_at'} })->get_column(' 1 / price');
  
  $c->stash->{nmc_last24} = $c->model("PokerNetwork::Trades")->search({
  status => 0, 
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  }, { order_by => { -desc => 'processed_at' } })->get_column('price');

  my $nmc7dmax = $c->stash->{nmc_last24}->max;
  my $btc7dmax = $c->stash->{btc_last24}->max;

  if( $btc7dmax > $nmc7dmax ){
  $btc7dmax = sprintf('%.8f', $btc7dmax) + 0; #converts it back to float
  $c->stash->{high} = $btc7dmax;
  }else{$c->stash->{high} = $nmc7dmax;}
  
  my $nmc7dmin = $c->stash->{nmc_last24}->min;
  my $btc7dmin = $c->stash->{btc_last24}->min;
  $btc7dmin = sprintf('%.8f', $btc7dmin) + 0;
    
  if( $btc7dmin < $nmc7dmin ){
  $c->stash->{low} = $btc7dmin;
  }else{$c->stash->{low} = $nmc7dmin;}
   
   my $nmc7davg = $c->model("PokerNetwork::Trades")->search({
  status => 0, 
  -and => [{buy_currency => $bitcoin},{sell_currency => $other}],
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  }, { order_by => { -desc => 'processed_at' } })->count;
  my $btc7davg = $c->model("PokerNetwork::Trades")->search({
  status => 0, 
  -and => [{buy_currency => $other},{sell_currency => $bitcoin}],
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 7 DAY)' },
  }, { order_by => { -desc => 'processed_at' } })->count;  
  
  if( $nmc7davg != 0 and $btc7davg != 0 ){ 
  $c->stash->{avg} = (( $c->stash->{nmc_last24}->sum + $c->stash->{btc_last24}->sum) / ($nmc7davg + $btc7davg));
  $c->stash->{avg} = sprintf('%.8f', $c->stash->{avg}) + 0;
  }
}

sub history :Path('history') CaptureArgs(1){
  my ( $self, $c, $coin) = @_;
  $c->stash->{coin} = 2;
  $c->stash->{symbol} = 'NMC';
  if($coin eq 'solidcoin'){
  $c->stash->{coin} = 3;
  $c->stash->{symbol} = 'SLC';
  }

  $c->stash->{history} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  user_serial => $c->user->serial,
  }, { 
      order_by => { 
        -asc => 'amount' 
      } 
  });
}

sub orders :Path('orders') CaptureArgs(1){
  my ( $self, $c, $coin) = @_;
  $c->stash->{coin} = 2;
  $c->stash->{symbol} = 'NMC';
  if($coin eq 'solidcoin'){
  $c->stash->{coin} = 3;
  $c->stash->{symbol} = 'SLC';
  }
  $c->stash->{orders} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  user_serial => $c->user->serial,
  }, { 
      order_by => { 
        -asc => 'price' 
      } 
  });
}

sub trade :Chained('/') :Path('trade') CaptureArgs(1) :FormConfig{
  my ($self, $c, $coin) = @_;
  my $other = 2;
  $c->stash->{coin} = 2;
  $c->stash->{symbol} = 'NMC';
  if($coin eq 'solidcoin'){
  $other = 3;
  $c->stash->{coin} = 3;
  $c->stash->{symbol} = 'SLC';
  my $slc_balance = $c->user->balances->search({currency_serial => 3})->first;
  }
  
  my @options;
  if($coin eq undef){
   push (@options, ['1', 'Bitcoin']);
   push (@options, ['2', 'Namecoin']);
  }elsif($coin eq 'solidcoin'){
  $c->stash->{bcur} = 3;
   push (@options, ['1', 'Bitcoin']);
   push (@options, ['3', 'Solidcoin']);
  }

  my $form = $c->stash->{form};
   
  $form->get_field({name => 'trade_buy'})->options(\@options);
  $form->get_field({name => 'trade_sell'})->options(\@options);
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, {  order_by => { -desc => 'processed_at' }});
  
  $c->stash->{last_trade} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { order_by => { -desc => 'processed_at' }})->first;  
  
  my $sell_currency = $form->params->{trade_sell};
  my $buy_currency = $form->params->{trade_buy};
  my $price = $form->params->{trade_price};
  
  if ($form->submitted_and_valid and $sell_currency != $buy_currency and $price != 0) {
  #form values
  
  if( $sell_currency == 1 ){
  $price = 1 / $price;
  }
  my $amount = $form->params->{trade_amount};

  my $balance = $c->user->balances->search({currency_serial => $sell_currency})->first;
  
   $c->stash->{balance} = $balance;
   $c->stash->{current_balance} = $balance->amount;
   if ($balance->amount < $amount || $amount < 0.0010 )  {
      $form->get_field("trade_amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }
    $balance->amount(
      $balance->amount() - $amount
    );
    $balance->update();

   # Create Trade
   my $create = $c->model('PokerNetwork::Trades')->create({
      created_at => DateTime->now( time_zone => 'local' ),
      user_serial => $c->user->serial,
      sell_currency => $sell_currency,
      buy_currency => $buy_currency,
      amount => $amount,
      balance => $amount,
      price => $price,
      status => 1,
	# 1 == active, 0 == finished
	});
	
	## Try to process the transaction ##
	  my $invert_price = sprintf('%.8f', ( 1 / $create->price )); #adding 0.00 coverts it back to a float
	  $invert_price = $invert_price + 0.00000001;

      my $orders = $c->model('PokerNetwork::Trades')->search({
      status => 1,
      -and => [{buy_currency => $create->sell_currency},{sell_currency => $create->buy_currency}],
      price => { '<=', => $invert_price},
      }, {  order_by => {  -asc => 'price' } });
	
	  if( $orders->first != undef){

	  my $creator_balance;
	  my $update_balance; 
	  my $fee;
	  my $reward;
	  my $order; 
	  my $compare_price;
	 while( $orders->first != undef and $create->balance != 0 ){
	  $order = $c->model('PokerNetwork::Trades')->search({
      status => 1,
      -and => [{buy_currency => $create->sell_currency},{sell_currency => $create->buy_currency}],
      price => { '<=', => $invert_price},
      }, {  order_by => {  -asc => 'price' } })->first;
	    my $balance_bought = ($create->balance * ( 1 / $order->price)); #Figure how much is being taken out of the prospect order
	      
	    if( $order->balance > $balance_bought ){
	     #If the prospect order has a higher balance subract this new trade and update balance
	     my $new_balance = $order->balance - $balance_bought;
	     $order->balance($new_balance);    
   	     $order->update(); 
   	     
   	     #Then pay the coins of the prospect trade
   	       $update_balance = $order->user->balances->search({currency_serial => $sell_currency})->first;
	       $c->stash->{balance} = $update_balance;
   		   $c->stash->{current_balance} = $update_balance->amount;
           
           $fee = $create->balance * 0.002;
           $reward = $create->balance - $fee;
           
           $update_balance->amount(
      		 $update_balance->amount() + $reward
    	   );
    	   $update_balance->update();
    	 #Payout the coins of the new trade
    	   $creator_balance = $create->user->balances->search({currency_serial => $buy_currency})->first;
	       $c->stash->{balance} = $creator_balance;
   		   $c->stash->{current_balance} = $creator_balance->amount;
           
           $fee = $balance_bought * 0.002;
           $reward = $balance_bought - $fee;
           
           $creator_balance->amount(
      	   	 $creator_balance->amount() + $reward
    	   );
    	   $creator_balance->update();
    	 #Since this new trade got entirely filled we set the status of the transaction update balance

    	   $compare_price =  ( 1 / $order->price );
 		   
    	   $create->price($compare_price);
    	   $create->balance(0);
    	   $create->status(0);
    	   $create->processed_at(DateTime->now( time_zone => 'local' ));
    	   $create->update();
    	   
	    }elsif($order->balance < $balance_bought ){
	    #If the prospect order has a lower balance subract this order from the new trade and update both balances
	     my $remaining_balance = $balance_bought - $order->balance;

   	     #convert back so balance can be updated
   	     my $c_new_balance = $remaining_balance * $order->price;
   	     
   	     $create->balance($c_new_balance);
   	     $create->update();
	
	    #Payout the coins of the new trade
    	   $creator_balance = $create->user->balances->search({currency_serial => $buy_currency})->first;
	       $c->stash->{balance} = $creator_balance;
   		   $c->stash->{current_balance} = $creator_balance->amount;
           
           $fee = $order->balance * 0.002;
           $reward = $order->balance - $fee;
           
           $creator_balance->amount(
      	   	 $creator_balance->amount() + $reward
    	   );
    	   $creator_balance->update();
		#Then pay the coins of the prospect trade
   	       my $update_balance = $order->user->balances->search({currency_serial => $sell_currency})->first;
	       $c->stash->{balance} = $update_balance;
   		   $c->stash->{current_balance} = $update_balance->amount;
           
           my $calculated_return = $order->balance * $order->price;
           
           $fee = $calculated_return * 0.002;
           $reward = $calculated_return - $fee;
           
           $update_balance->amount(
      		 $update_balance->amount() + $reward
    	   );
    	   $update_balance->update();
    	 #Since this looked up trade got entirely filled we set the status of the transaction update balance
		   
    	   $compare_price = $order->price;
		   
    	   $order->price($compare_price);
    	   $order->balance(0);
    	   $order->status(0);
    	   $order->processed_at(DateTime->now( time_zone => 'local' ));
    	   $order->update();
	    
	    }elsif($order->balance == $balance_bought ){
	    #since they are the same we can simply pay out each balance to the other user
	    #Payout the coins of the new trade
    	   $creator_balance = $create->user->balances->search({currency_serial => $buy_currency})->first;
	       $c->stash->{balance} = $creator_balance;
   		   $c->stash->{current_balance} = $creator_balance->amount;
           
           $fee = $order->balance * 0.002;
           $reward = $order->balance - $fee;
           
           $creator_balance->amount(
      	   	 $creator_balance->amount() + $reward
    	   );
    	   $creator_balance->update();
		#Then pay the coins of the prospect trade
   	       my $update_balance = $order->user->balances->search({currency_serial => $sell_currency})->first;
	       $c->stash->{balance} = $update_balance;
   		   $c->stash->{current_balance} = $update_balance->amount;
           
           $fee = $create->balance * 0.002;
           $reward = $create->balance - $fee;
           
           $update_balance->amount(
      		 $update_balance->amount() + $reward
    	   );
    	   $update_balance->update();
		 #Since we finished both trades at once we close them both out and empty their balances
    	   $order->balance(0);
    	   $order->status(0);
    	   $order->processed_at(DateTime->now( time_zone => 'local' ));
    	   $order->update();
    	   
    	   $create->balance(0);
    	   $create->status(0);
    	   $create->processed_at(DateTime->now( time_zone => 'local' ));
    	   $create->update();
	    }  
	  }
	  
	}
	
	## End processing ##

    push @{$c->flash->{messages}}, "You have posted an order.";
    if($coin eq 'solidcoin'){
    $c->res->redirect($c->uri_for('/exchange/orders/solidcoin'));
    }else{
    $c->res->redirect($c->uri_for('/exchange/orders'));}
  };   
}

sub base :Chained('/') PathPart('exchange/order') CaptureArgs(1) {
     my ($self, $c, $id) = @_;
     my $order = $c->model('PokerNetwork::Trades')->find($id);


     if ( $order == undef ) {
         $c->stash( error_msg => "This order does not exist" );
     } else {
         $c->stash( order => $order );
     }
}

sub cancel :Chained('base') :PathPart('cancel') :Args(0) {
  my ($self, $c) = @_;
  my $order = $c->stash->{order};
    if ( $c->stash->{order} == undef ){
         $c->res->redirect(
      $c->uri_for('/exchange/orders')
    );
     }else{
  #return balance
  my $coin;
  if($order->buy_currency == 3 or $order->sell_currency == 3){
    $coin = 3;
  }
  if($order->status == 1){
   	my $update_balance = $order->user->balances->search({currency_serial => $order->sell_currency})->first;
	$c->stash->{balance} = $update_balance;
    $c->stash->{current_balance} = $update_balance->amount;
                   
    $update_balance->amount(
     $update_balance->amount() + $order->balance
    );   
    $update_balance->update();

    $order->delete;
 
    push @{$c->flash->{messages}}, "The order has been cancelled and the remaining balance returned.";
 if($coin == 3){
    $c->res->redirect($c->uri_for('/exchange/orders/solidcoin'));
    }else{
    $c->res->redirect($c->uri_for('/exchange/orders'));}
   }
  }
}
=head1 AUTHOR

mrmoon

=head1 LICENSE

mrmooncoin@gmail.com

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;