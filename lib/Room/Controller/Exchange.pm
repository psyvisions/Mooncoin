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
  my $primary = 1;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->res->redirect($c->uri_for('/user'));
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
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, { cache => 1, rows => 25, order_by => { -desc => 'processed_at' }});
  
  $c->stash->{last_trade} = $c->stash->{recent_trades}->search(undef, { rows => 1 })->single;  

  $c->stash->{ask_buy} = $c->stash->{buy_nmc}->search(undef, { rows => 1 })->single;    
  
  $c->stash->{ask_sell} = $c->stash->{sell_nmc}->search(undef, { rows => 1 })->single;  
  
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

  $c->stash->{nmc_7dvolume} = $c->stash->{btc_total} + $c->stash->{nmc_total};
  
  my $btc7d = $c->stash->{btc_hold}->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 1 DAY)' },})->get_column('price');
  my $nmc7d = $c->stash->{nmc_hold}->search({ 
  processed_at => { '>=' => \'DATE_SUB(CURDATE(),INTERVAL 1 DAY)' },})->get_column('1 / price');  

  my $nmc7dmax = $nmc7d->max;
  my $btc7dmax = $btc7d->max;

  if( $btc7dmax > $nmc7dmax ){
  $c->stash->{high} = $btc7dmax;
  }else{$c->stash->{high} = $nmc7dmax;}
  
  my $nmc7dmin = $nmc7d->min;
  my $btc7dmin = $btc7d->min;;
    
  if( $btc7dmin < $nmc7dmin ){
  $c->stash->{low} = $btc7dmin;
  }else{$c->stash->{low} = $nmc7dmin;}
  
  $c->stash->{avg} = (( $c->stash->{low} + $c->stash->{high}) / 2);
}

sub graph :Path('graph') CaptureArgs(1){
  my ( $self, $c, $coin) = @_;

  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef){
	$other = 0;
	$c->res->redirect($c->uri_for('/user'));
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }
  
    $c->stash->{rt_graph} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, {rows => 75, order_by => { -desc => 'processed_at' }});
  
}

sub history :Path('history') CaptureArgs(1){
  my ( $self, $c, $coin) = @_;

  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef or !$c->user){
	$other = 0;
	$c->res->redirect($c->uri_for('/user'));
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }

  $c->stash->{history} = $c->model("PokerNetwork::Trades")->search({
  status => [0,999],
  -or => [{buy_currency => $other},{sell_currency => $other}],
  user_serial => $c->user->serial,
  }, { 
     order_by => { -desc => 'processed_at' }
  });
}

sub orders :Path('orders') CaptureArgs(1){
  my ( $self, $c, $coin) = @_;
  
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef or !$c->user){
	$other = 0;
	$c->res->redirect($c->uri_for('/user'));
	return;
  }else{
    $other = $c->stash->{coin}->serial;
  }

  $c->stash->{orders} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  user_serial => $c->user->serial,
  }, { 
      order_by => { 
        -asc => 'price' 
      } 
  });
}

sub trade :Chained('/') :Path('trade') CaptureArgs(1) :FormConfig{
  my ($self, $c, $coin) = @_;

  
  my @options;
  $c->stash->{coin} = $c->model("PokerNetwork::Currencies")->search({name => $coin, serial => {'!=' => '1'}}, { rows => 1})->single;
  
  my $other;
  if($c->stash->{coin} == undef or !$c->user){
	$other = 0;
	$c->res->redirect($c->uri_for('/user'));
	return;
  }else{
    $other = $c->stash->{coin}->serial;
    push (@options, ['1', 'Bitcoin']);
    push (@options, [ $c->stash->{coin}->serial , ucfirst($c->stash->{coin}->name)]);
  }

  my $form = $c->stash->{form};
   
  $form->get_field({name => 'trade_buy'})->options(\@options);
  $form->get_field({name => 'trade_sell'})->options(\@options);
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  -or => [{buy_currency => $other},{sell_currency => $other}],
  }, {  order_by => { -desc => 'processed_at' }});
  
  $c->stash->{last_trade} = $c->stash->{recent_trades}->first;  
  
  my $sell_currency = $form->params->{trade_sell};
  my $buy_currency = $form->params->{trade_buy};
  my $price = $form->params->{trade_price};
  
  if ($form->submitted_and_valid and $sell_currency != $buy_currency and $price != 0) {
  
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
	  my $invert_price = sprintf('%.4f', ( 1 / $create->price )); #adding 0.00 coverts it back to a float
	  $invert_price = $invert_price + 0.0001;

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
      #Figure how much is being taken out of the prospect order
      my $balance_bought = ($create->balance * ( 1 / $order->price)); 	 
           
	     if( $order->balance > $balance_bought ){
	     #If the prospect order has a higher balance subract this new trade and update balance
	     my $new_balance = $order->balance - $balance_bought;
	     $order->balance($new_balance); 
	     my $new_bought = $order->bought + $balance_bought;
	     $order->bought($new_bought);
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

    $c->res->redirect($c->uri_for('/exchange/orders/' . $c->stash->{coin}->name ));


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
    if ( $c->stash->{order} == undef or !$c->user){
      $c->res->redirect($c->uri_for('/user' ));
      return;
     }else{
  #return balance
  
  if($order->status == 1){
   	my $update_balance = $order->user->balances->search({currency_serial => $order->sell_currency})->first;
	$c->stash->{balance} = $update_balance;
    $c->stash->{current_balance} = $update_balance->amount;
                   
    $update_balance->amount(
     $update_balance->amount() + $order->balance
    );   
    $update_balance->update();
    
    my $return;
    if($order->buy_currency == 3 or $order->sell_currency == 3){
      $return = 'solidcoin'; 
    }elsif($order->buy_currency == 2 or $order->sell_currency == 2){ 
      $return = 'namecoin'; 
    }
    else{
    $return = 'solidcoin'; 
    }
    
    my $bought = $order->amount - $order->balance; 
    $order->amount($bought);
    $order->balance(0);
    $order->status(999);
    $order->processed_at(DateTime->now( time_zone => 'local' ));
    $order->update();
    
    push @{$c->stash->{messages}}, "The order has been cancelled and the remaining balance returned.";
    $c->res->redirect(
      $c->uri_for( '/exchange/orders/' . $return )
    );

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