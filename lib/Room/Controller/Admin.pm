package Room::Controller::Admin;
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

sub base :Chained :PathPart('admin') :CaptureArgs(0) {
  my ($self, $c) = @_;

  if (!$c->user || $c->user->privilege != 2) {
    $c->detach( '/default' );
  }
}


sub index :Chained('base') :PathPart('') :Args(0) {
  my ($self, $c) = @_;

  $c->stash->{bitcoin_balance} = $c->model("BitcoinServer")->get_balance();

  my $rs = $c->model("PokerNetwork::User2Money")->search(
            { currency_serial => 1 },
            {
              '+select' => [{ SUM => 'amount' }],
              '+as'     => [qw/total_amount/],
           });

  my $row = $rs->first;

  $c->stash->{total_ingame_balance_btc} = $row->get_column('total_amount') / 10000;
  
  ##
  
  $c->stash->{namecoin_balance} = $c->model("NamecoinServer")->get_balance();

  my $rs1 = $c->model("PokerNetwork::User2Money")->search(
            { currency_serial => 2 },
            {
              '+select' => [{ SUM => 'amount' }],
              '+as'     => [qw/total_amount/],
           });

  my $row1 = $rs1->first;

  $c->stash->{total_ingame_balance_nmc} = $row1->get_column('total_amount') / 10000;
  
}


sub users :Chained('base') :Args(0) {
  my ($self, $c) = @_;
  my $name = $c->req->params->{'name'} || '';
  my $email = $c->req->params->{'email'} || '';
  my $page = $c->req->params->{'page'} || 0;
  $page = 1 if $page < 1;

  $c->stash->{users} = $c->model('PokerNetwork::Users')->search(undef, {
    rows => 50,
    page => $page,
    order_by => 'name' 
  });

  $c->stash->{users} = $c->stash->{users}->search({ 'name' => { 'LIKE' => '%'. $name .'%' } }) unless $name eq '';
  $c->stash->{users} = $c->stash->{users}->search({ 'email' => { 'LIKE' => '%'. $email .'%' } }) unless $email eq '';
}



sub user :Chained('base') :CaptureArgs(1) {
  my ($self, $c, $user_id) = @_;
  
  $c->stash->{user} = $c->model("PokerNetwork::Users")->find($user_id);
}

sub kick :Chained('user') :Args(0) {
  my ($self, $c) = @_;

}

sub profile :Chained('user') :PathPart('') :Args(0) {}


sub hands :Chained('user') :Args(0) {
  my ($self, $c) = @_;
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{hands} = $c->stash->{user}->hands->search(undef, {
    rows => 50,
    page => $page,
    order_by => {
      -desc => 'serial',
    }
  });

  $c->stash->{template} = 'user/hand/index';
}


sub view_hand :Chained('user') :PathPart('hands') :Args(1) {
  my ($self, $c, $id) = @_;

  my $hand = $c->model('PokerNetwork::Hands')->search({serial => $id})->first;

  if (! $hand) {
    $c->detach('/default');
  }

  $c->stash->{hand} = $hand->get_parsed_history;
  
  $c->stash->{template} = 'user/hand/view_hand';
}


sub withdrawals :Chained('base') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{withdrawals} = $c->model("PokerNetwork::Withdrawal")->search({}, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'withdrawal_id' 
      } 
  });
}


sub withdrawal_base :Chained('base') :PathPart('withdrawal') :CaptureArgs(1) {
  my ($self, $c, $id) = @_;

  my $withdrawal = $c->model("PokerNetwork::Withdrawal")->find($id);

  if (! $withdrawal) {
    $c->detach( '/default' );
  }

  $c->stash->{withdrawal} = $withdrawal;
}


sub withdrawal :Chained('withdrawal_base') :PathPart('') :Args(0) {
  my ($self, $c) = @_;
}

sub withdrawal_info :Chained('withdrawal_base') :PathPart('info') :Args(0) {
  my ($self, $c) = @_;

  $c->stash->{withdrawal}->info(
    $c->req->param('withdrawal_info')
  );
  $c->stash->{withdrawal}->update();
  
  push @{$c->flash->{messages}}, "Order additional info updated.";

  $c->res->redirect(
    $c->uri_for('/admin/withdrawal/' . $c->stash->{withdrawal}->id)
  );
}


sub withdrawal_reprocess :Chained('withdrawal_base') :PathPart('reprocess') :Args(0) {
  my ($self, $c) = @_;
  my $withdrawal = $c->stash->{withdrawal};

  # Hardcoded to handle only Bitcoins right now
  if ($withdrawal->currency->serial == 1) {
    my $result = $c->model("BitcoinServer")->send_to_address($withdrawal->dest, $withdrawal->amount);

    if (! $c->model('BitcoinServer')->api->error) {
      # Mark as processed if successful
      $withdrawal->processed_at( DateTime->now(time_zone => 'local') );
      $withdrawal->processed(1);
      $withdrawal->update();

      push @{$c->flash->{messages}}, "Order reprocessed. Bitcoins sent.";
    }
    else {
      push @{$c->flash->{errors}}, "Bitcoins not sent. Here is daemon answer: <pre>\n" . Dumper($result);
    }
  }
  else {
    push @{$c->flash->{errors}}, "Currently, only one currency supported. Currency serial should be equal 1.";
  }
  
   # Hardcoded to handle only Namecoins right now
  if ($withdrawal->currency->serial == 2) {
    my $result = $c->model("NamecoinServer")->send_to_address($withdrawal->dest, $withdrawal->amount);

    if (! $c->model('NamecoinServer')->api->error) {
      # Mark as processed if successful
      $withdrawal->processed_at( DateTime->now() );
      $withdrawal->processed(1);
      $withdrawal->update();

      push @{$c->flash->{messages}}, "Order reprocessed. Namecoins sent.";
    }
    else {
      push @{$c->flash->{errors}}, "Namecoins not sent. Here is daemon answer: <pre>\n" . Dumper($result);
    }
  }
  else {
    push @{$c->flash->{errors}}, "Currently, only one currency supported. Currency serial should be equal 1.";
  }

  
  
  $c->res->redirect(
    $c->uri_for('/admin/withdrawal/' . $withdrawal->id)
  );
}


sub mark :Chained('withdrawal_base') :CaptureArgs(0) {
  my ($self, $c) = @_;
}


sub mark_processed :Chained('mark') :PathPart('processed') {
  my ($self, $c) = @_;
  
  $c->stash->{withdrawal}->processed_at( DateTime->now() );
  $c->stash->{withdrawal}->processed(1);
  $c->stash->{withdrawal}->update();

  push @{$c->flash->{messages}}, "Withdrawal marked processed.";
  $c->res->redirect(
    $c->uri_for('/admin/withdrawal/' . $c->stash->{withdrawal}->id)
  );
}

sub mark_unprocessed :Chained('mark') :PathPart('unprocessed') {
  my ($self, $c) = @_;

  $c->stash->{withdrawal}->processed_at(undef);
  $c->stash->{withdrawal}->processed(undef);
  $c->stash->{withdrawal}->update();

  push @{$c->flash->{messages}}, "Withdrawal marked unprocessed.";
  $c->res->redirect(
    $c->uri_for('/admin/withdrawal/' . $c->stash->{withdrawal}->id)
  );
}

sub mark_canceled :Chained('mark') :PathPart('canceled') {
  my ($self, $c) = @_;
  
  $c->stash->{withdrawal}->processed_at(DateTime->now());
  $c->stash->{withdrawal}->processed( -1 );
  $c->stash->{withdrawal}->update();
  
  push @{$c->flash->{messages}}, "Order canceled.";
  $c->res->redirect(
    $c->uri_for('/admin/withdrawal/' . $c->stash->{withdrawal}->id)
  );
}

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
  
  $bet->active('1');
  $bet->finished_at(DateTime->now);
  $bet->update();
  
  push @{$c->flash->{messages}}, "This bet has been cancelled and a the funds have been freezed.";
  
  $c->res->redirect(
      $c->uri_for('/admin/reports')
    );
}

## bet backend for processing and conflict resolution ##

sub bet_base :Chained('base') :PathPart('bet') :CaptureArgs(1) {
  my ($self, $c, $id) = @_;

  my $bet = $c->model("PokerNetwork::Bets")->find($id);

  if (! $bet) {
    $c->detach( '/default' );
  }

  $c->stash->{bet} = $bet;
}

sub bets :Chained('base') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  active => undef
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub ready :Chained('base') :Path('bets/ready') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  -or => [{-or => [{-and => [ { challenger_status => '3' }, { user_status => '3' } ]},{-and => [ { challenger_status => '2' }, { user_status => '1' } ]}]},{-or => [{-and => [ { challenger_status => '1' }, { user_status => '2' } ]}]}],
  active => undef
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub conflict :Chained('base') :Path('bets/conflict') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  
  -or => [{-or => [{ -or => [{-and => [ { challenger_status => '1' }, { user_status => '1' } ]},{-and => [ { challenger_status => '2' }, { user_status => '2' } ]}]},{ -or => [{-and => [ { challenger_status => '3' }, { user_status => '1' } ]},{-and => [ { challenger_status => '1' }, { user_status => '3' } ]}]}]},{-or => [{ -or => [{-and => [ { challenger_status => '2' }, { user_status => '3' } ]},{-and => [ { challenger_status => '3' }, { user_status => '2' } ]}]}]}],
  active => undef
  
 
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub finished :Chained('base') :Path('bets/finished') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
    active => ['0','1']
 
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub timedout :Chained('base') :Path('bets/timedout') :Args(0) {
  my ($self, $c) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
    active => undef,
 
  }, { 
      page => $page,
      order_by => { 
        -desc => 'title' 
      } 
  });
}

sub view_bet :Chained('bet_base') :PathPart('view') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};  

           ## Total side one amount
     $c->stash->{userbets_s_one_total} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial, side => 1}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_one = $c->stash->{userbets_s_one_total}->first;

     $c->stash->{total_side_one} = $row_one->get_column('total_amount');
     ## Total side two amount
     $c->stash->{userbets_s_two_total} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial, side => 2}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_two = $c->stash->{userbets_s_two_total}->first;

     $c->stash->{total_side_two} = $row_two->get_column('total_amount');  
 
     $c->stash->{userbets_s_two} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial,
     side => 2,
     
  }, { 
      order_by => { 
        -desc => 'created_at' 
      } 
  });
      

     ##

     $c->stash->{userbets_s_one} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial,
     side => 1,}, {order_by => { 
        -desc => 'created_at' } });
  
}

sub bet_process :Chained('bet_base') :PathPart('process') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  my $fees;
  my $amount_due;
  
  if($bet->type == 2){
  my $amount = $c->stash->{bet}->amount;
  
  if( $bet->user_status == '1' and $bet->challenger_status == '2' ){
  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $u_balance) {
    my $amount = $amount * 2;
    $u_balance = $c->stash->{bet}->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $u_balance->amount(0);
    $u_balance->update();
  }
  
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;

    $u_balance->amount(
      $u_balance->amount() + ( $amount_due / 100 )
    );
    $u_balance->update();
  
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
   push @{$c->flash->{messages}}, "Author Won!";
  }
  elsif( $bet->user_status == '2' and $bet->challenger_status == '1' ){
  my $amount = $amount * 2;
   my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $c_balance) {
    $c_balance = $c->stash->{bet}->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
  
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();
    
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  push @{$c->flash->{messages}}, "Challenger Won!";
  }
  elsif($bet->user_status == '3' and $bet->challenger_status == '3'){
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
   if (! $c_balance) {
    $c_balance = $c->stash->{bet}->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
  
     $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $u_balance) {
    $u_balance = $c->stash->{bet}->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $u_balance->amount(0);
    $u_balance->update();
  }

    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;

    $u_balance->amount(
      $u_balance->amount() + ( $amount_due / 100 )
    );
    $u_balance->update();
    
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
    
  push @{$c->flash->{messages}}, "Draw";
  }
  else{
  push @{$c->flash->{messages}}, "Can't determine conclusion.";
  }

  $c->res->redirect(
      $c->uri_for('/admin/bets')
    );
    }elsif($bet->type = 1){  
    
    }
}

sub determine :Chained('bet_base') :PathPart('determine') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  my $form = $c->stash->{form};
  my $userbet;
  my $reward;
  my $fees;
  my $amount_due;
   
     ## Total side one amount
     $c->stash->{userbets_s_one_total} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial, side => 1}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_one = $c->stash->{userbets_s_one_total}->first;

     $c->stash->{total_side_one} = $row_one->get_column('total_amount');
     
     ## Total side two amount
     $c->stash->{userbets_s_two_total} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial, side => 2}, {'+select' => [{ SUM => 'amount' }],'+as' => [qw/total_amount/], });
           
     my $row_two = $c->stash->{userbets_s_two_total}->first;

     $c->stash->{total_side_two} = $row_two->get_column('total_amount');  
 
     $c->stash->{userbets_s_two} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial,
     side => 2, }, { order_by => {  -desc => 'created_at' }  });
  
     $c->stash->{userbets_s_one} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial, side => 1,});
     
  ## Side 1 and 2
  if ($form->submitted_and_valid) {
  my $result = $form->params->{bet_choose_winner};

  if($result == 1){
    
  foreach $userbet( $bet->userbets ) { 
   my $ratio = $bet->get_ratio; 
   my $h_side = $bet->get_h_side;
   my $amount = $userbet->amount;
   my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;
   
   if($userbet->side == 1){

   
    if (! $balance) {
      $balance = $userbet->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
      $balance->amount(0);
      $balance->update();
    }
    
    if( $h_side == 1 ){
    $reward = ($amount / $ratio);
    $fees = ($amount + $reward) * 0.01;
    $amount_due = ($amount + $reward) - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }elsif( $h_side == 2 ){
    $reward = $amount * $ratio;
    $fees = ($amount + $reward) * 0.01; #Figure out fees
    $amount_due = ($amount + $reward) - $fees;
        
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }else{
    $reward = $amount * 1;
    $fees = ($amount + $reward) * 0.01; #Figure out fees
    $amount_due = ($amount + $reward) - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }
   
   #update status for winner  
  }

  }
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
   push @{$c->flash->{messages}}, "Side One wins!" . $result;
    
    $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
    );


  }elsif($result == 2){
  
    foreach $userbet( $bet->userbets ) { 
   my $ratio = $bet->get_ratio; 
   my $h_side = $bet->get_h_side;
   my $amount = $userbet->amount;
   my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;

   if($userbet->side == 2){

   
    if (! $balance) {
      $balance = $userbet->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
      $balance->amount(0);
      $balance->update();
    }
    
    if( $h_side == 2 ){
    $reward = ($amount / $ratio);
    $fees = ($amount + $reward) * 0.01;
    $amount_due = ($amount + $reward) - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }elsif( $h_side == 1 ){
    $reward = $amount * $ratio;
    $fees = ($amount + $reward) * 0.01; #Figure out fees
    $amount_due = ($amount + $reward) - $fees;
        
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }else{
    $reward = $amount * 1;
    $fees = ($amount + $reward) * 0.01; #Figure out fees
    $amount_due = ($amount + $reward) - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    }
   
   #update status for winner  
  }

  }
    $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
   push @{$c->flash->{messages}}, "Side 2 wins ! " . $result;
    
    $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
    );

  ## Draw
  }elsif($result == 3){
  my $fees;
  my $amount_due;
  
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
    
    $c->stash->{bet}->active('0');
    $c->stash->{bet}->finished_at(DateTime->now);
    $c->stash->{bet}->update();
    
    push @{$c->flash->{messages}}, "Draw, everyone received their funds.";
    
    $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
    );   
  }
 } 
}

sub choose :Chained('bet_base') :PathPart('choose') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  my $form = $c->stash->{form};
  my $fees;
  my $amount_due;
  
  if( $bet->type == 2){
  
  if ($form->submitted_and_valid) {
  my $result = $form->params->{bet_choose_winner};
  
  ## Game of skill update
  my $amount = $c->stash->{bet}->amount;
  
  if( $result == '1' ){
  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $u_balance) {
    my $amount = $amount * 2;
    $u_balance = $c->stash->{bet}->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $u_balance->amount(0);
    $u_balance->update();
  }

    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;

    $u_balance->amount(
      $u_balance->amount() + ( $amount_due / 100 )
    );
    $u_balance->update();
  $c->stash->{bet}->challenger_status('2');
  $c->stash->{bet}->user_status('1');
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
   push @{$c->flash->{messages}}, "Author Won!";
  }
  elsif( $result == '2' ){
  my $amount = $amount * 2;
   my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $c_balance) {
    $c_balance = $c->stash->{bet}->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
  
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();
    
  $c->stash->{bet}->challenger_status('1');
  $c->stash->{bet}->user_status('2');
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  push @{$c->flash->{messages}}, "Challenger Won!";
  }
  elsif( $result == '3' ){
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
   if (! $c_balance) {
    $c_balance = $c->stash->{bet}->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
  
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $u_balance) {
    $u_balance = $c->stash->{bet}->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $u_balance->amount(0);
    $u_balance->update();
  }

    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;

    $u_balance->amount(
      $u_balance->amount() + ( $amount_due / 100 )
    );
    $u_balance->update();
  
  $c->stash->{bet}->challenger_status('3');
  $c->stash->{bet}->user_status('3');
  $c->stash->{bet}->active('0');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
    
  push @{$c->flash->{messages}}, "Draw";
  }
  else{
  push @{$c->flash->{messages}}, "Can't determine conclusion.";
  }
  

  
  $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
    );
  }  }else{
  push @{$c->flash->{messages}}, "Wrong bet type.";
  $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
    );
  }
 }


sub bet_cancel :Chained('bet_base') :PathPart('cancel') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  my $fees;
  my $amount_due;
  my $username;
  my $userbet;
  if( $bet->type == 2 ){
  my $amount = $c->stash->{bet}->amount;
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
   if (! $c_balance) {
    $c_balance = $c->stash->{bet}->challenger->balances->find_or_create({ currency_serial => $bet->currency_serial });
    $c_balance->amount(0);
    $c_balance->update();
  }
  
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
  
      $c_balance->amount(
      $c_balance->amount() + ( $amount_due / 100 )
    );
    $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
   if (! $u_balance) {
    $u_balance = $c->stash->{bet}->user->balances->find_or_create({ currency_serial => $bet->currency_serial });
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
    $userbet->delete;
    
    }
  $c->res->redirect(
      $c->uri_for('/admin/reports')
    );   
  }
  
  $bet->delete;
 
  push @{$c->flash->{messages}}, "The bet has been cancelled and the coins have been returned." ;
  
  $c->res->redirect(
      $c->uri_for('/admin/bets')
    );     
}


sub bet_freeze :Chained('bet_base') :PathPart('freeze') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  $c->stash->{bet}->active('1');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
  push @{$c->flash->{messages}}, "This bet has been cancelled and a the coins have been frozen.";
  
  $c->res->redirect(
      $c->uri_for('/admin/bet/' . $bet->serial . '/view')
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

