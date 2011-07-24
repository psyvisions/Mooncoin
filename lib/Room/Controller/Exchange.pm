package Room::Controller::Exchange;
use Moose;
use namespace::autoclean;
use DateTime;
use Data::Dumper;
use String::Random;
use POSIX;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

Room::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut


sub index :Path {
  my ( $self, $c) = @_;

  $c->stash->{buy_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  buy_currency => 2,
  sell_currency => 1,
  }, { 
      order_by => { 
        -asc => 'price' 
      } 
  });
  
  $c->stash->{sell_nmc} = $c->model("PokerNetwork::Trades")->search({
  status => 1,
  buy_currency => 1,
  sell_currency => 2,
  }, { 
      order_by => { 
        -asc => 'price' 
      } 
  });
  
  $c->stash->{recent_trades} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  }, { 
      order_by => { 
        -asc => 'processed_at' 
      } 
  });

}

sub history :Path('history') {
  my ( $self, $c) = @_;

  $c->stash->{history} = $c->model("PokerNetwork::Trades")->search({
  status => 0,
  user_serial => $c->user->serial,
  }, { 
      order_by => { 
        -asc => 'amount' 
      } 
  });
}

sub orders :Path('orders') {
  my ( $self, $c) = @_;

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
  my ($self, $c, $id) = @_;
  my $trade = $c->model('PokerNetwork::Trades')->find($id);
  my $form = $c->stash->{form};
 
  #form values
  my $sell_currency = $form->params->{trade_sell};
  my $buy_currency = $form->params->{trade_buy};  
  my $amount = $form->params->{trade_amount};
  my $price = $form->params->{trade_price};
 
  if ( $trade == undef ) {
   $c->stash( error_msg => "This item does not exist" );
  } else {
   $c->stash( trade => $trade );
  }

  if ($form->submitted_and_valid and $sell_currency != $buy_currency) {
  
  my $balance = $c->user->balances->search({currency_serial => $sell_currency})->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => $sell_currency });
    $balance->amount(0);
    $balance->update();
  }
  
   $c->stash->{balance} = $balance;
   $c->stash->{current_balance} = $balance->amount;
  
  
    if ($balance->amount < $amount || $amount < 0.01 )  {
      $form->get_field("trade_amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }

    $balance->amount(
      $balance->amount() - $amount
    );
    $balance->update();

  
  # Create report
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
	  my $invert_price = ( 1 / $create->price );
  
      my $orders = $c->model('PokerNetwork::Trades')->search({
      status => 1,
      user_serial => { '!=', $create->user->serial},
      buy_currency => $create->sell_currency,
      price => { '<=', => $invert_price},
      }, {  order_by => {  -asc => 'price' } });
	
	
	  if( $orders->first != undef){

	  my $creator_balance;
	  my $update_balance; 
	  my $fee;
	  my $reward;
	  my $order; 
	 while( $orders->first != undef and $create->balance != 0 ){
	   #my $compare_price = ( 1 / $order->price ); dont need this yet
	  $order = $c->model('PokerNetwork::Trades')->search({
      status => 1,
      user_serial => { '!=', $create->user->serial},
      buy_currency => $create->sell_currency,
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
    $c->res->redirect($c->uri_for('/exchange/orders'));
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
    $c->res->redirect(
      $c->uri_for('/exchange/orders')
    );
}
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