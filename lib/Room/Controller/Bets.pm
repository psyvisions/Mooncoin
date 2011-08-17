package Room::Controller::Bets;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use String::Random;
use POSIX;
use DateTime;

BEGIN {extends 'Catalyst::Controller::HTML::FormFu'; }

=head1 NAME

Room::Controller::Bets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
  my ($self, $c) = @_;

  if (!$c->user && $c->action->private_path !~ /bet\/(foresight|skill)/) {
    $c->res->redirect(
      $c->uri_for('/user/login', '')
    );
    return;
  }
  if (!$c->user && $c->action->private_path !~ /bets\/(namecoin|bitcoin)/) {
    $c->res->redirect(
      $c->uri_for('/user/login', '')
    );
    return;
  }
  1;
}

=head2 index

=cut


sub index :Path :CaptureArgs(2) {
  my ( $self, $c, $game, $category) = @_;
  
   my @userbets = ();
  $c->stash->{user_bets} = $c->model("PokerNetwork::User2bet")->search({
  user_serial => $c->user->serial,
  });
 
  while ( my $holder = $c->stash->{user_bets}->next ){
  push(@userbets, $holder->bet_serial );
  }  

  
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
    $c->stash->{game} = $game;
  $c->stash->{category} = $category;
  if( $game eq 'skill'){$game = 2;}
  elsif( $game eq 'foresight' ){$game = 1;}
  elsif( $game == undef ){$game = [1,2];}
  else{$game = [1,2];}

  if($category == undef){ 
  $category = [1..9];
  }
  
  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  -or => [{-or => [{user_serial => $c->user->serial},{challenger_serial => $c->user->serial}]},{serial => \@userbets }],
  active => undef,
  type => $game,
  category => $category,
  }, { 
      rows => 5,
      page => $page,
      order_by => { 
        -asc => 'deadline' 
      } 
  });
}

## NMC bet views ##
sub nmc_bets :Path('namecoin')  :CaptureArgs(2) {
  my ( $self, $c, $game, $category) = @_;

  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
  $c->stash->{game} = $game;
  $c->stash->{category} = $category;
  if( $game eq 'skill'){$game = 2;}
  elsif( $game eq 'foresight' ){$game = 1;}
  elsif( $game == undef ){$game = [1,2];}
  else{$game = [1,2];}
  
  if($category == undef){ 
  $category = [1..9];
  }
  
  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  currency_serial => 2,
  active => undef,
  type => $game,
  category => $category,
  }, { 
      rows => 20,
      page => $page,
      order_by => { 
        -asc => 'deadline' 
      } 
  });
}


## BTC bet views ##
sub btc_bets :Chained('base') :Path('bitcoin')  :CaptureArgs(2) {
  my ( $self, $c, $game, $category) = @_;
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;

  $c->stash->{game} = $game;
  $c->stash->{category} = $category;
  
  if( $game eq 'skill'){$game = 2;}
  elsif( $game eq 'foresight' ){$game = 1;}
  elsif( $game == undef ){$game = [1,2];}
  else{$game = [1,2];}
 
  if($category == undef){ 
  $category = [1..9];
  }

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  currency_serial => 1,
  active => undef,
  type => $game,
  category => $category,
  }, { 
      rows => 20,
      page => $page,
      order_by => { 
        -asc => 'deadline' 
      } 
  });
}

sub awaiting_challenger :Path('awaiting_challenger')  :CaptureArgs(2) {
  my ( $self, $c ) = @_;
  
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
 
  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({ 
  user_serial => $c->user->serial, 
  type => 2,
  challenger_serial => undef, 
  }, { 
      rows => 5,
      page => $page,
      order_by => { 
        -desc => 'created_at' 
      } 
  });
  
}

sub awaiting_update :Path('awaiting_update') :Args(0) {
  my ( $self, $c ) = @_;
  
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
 
  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({ 
  -and => [{-or => [ { challenger_serial => $c->user->serial }, { user_serial => $c->user->serial } ] },{-or => [ { challenger_status => undef }, { user_status => undef } ]}],
    challenger_serial => {'!=' => 'undef'},
  }, { 
      rows => 20,
      page => $page,
      order_by => { 
        -desc => 'created_at' 
      } 
  });
}

sub complete  :Path('complete') :Args(0) {
  my ( $self, $c ) = @_;
  my $page = $c->req->params->{'page'};
  $page = 1 if $page < 1;
  
  my @userbets = ();
  $c->stash->{user_bets} = $c->model("PokerNetwork::User2bet")->search({
  user_serial => $c->user->serial,
  });
 
  while ( my $holder = $c->stash->{user_bets}->next ){
  push(@userbets, $holder->bet_serial );
  }  

  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  active => [1..4],
  -or => [{-or => [{user_serial => $c->user->serial},{challenger_serial => $c->user->serial}]},{serial => \@userbets }],
  }, 
  { 
      rows => 20,
      page => $page,
      order_by => { 
        -desc => 'created_at' 
      } 
  });
}

sub base :Chained('/') PathPart('bet') CaptureArgs(1) {
     my ($self, $c, $id) = @_;
     my $bet = $c->model('PokerNetwork::Bets')->find($id);

     if ( $bet == undef ) {
         $c->stash( error_msg => "This item does not exist" );
     } else {
         $c->stash( bet => $bet );
     }
}

sub foresight :Path('/bet/foresight') :FormConfig CaptureArgs(1) { 
  my ( $self, $c, $currency ) = @_;
  my $form = $c->stash->{form};
  
  if($currency eq 'bitcoin'){
  $currency = 1;
  }elsif($currency eq 'namecoin'){
  $currency = 2;
  }elsif($currency == undef){
    $c->res->redirect(
      $c->uri_for('/bets')
    );
    $currency = 1;
  }else{
      $c->res->redirect(
      $c->uri_for('/bets')
    );
    $currency = 1;
  }

  if ($form->submitted_and_valid) {

  my $title = $form->params->{bet_title};
  my $description = $form->params->{bet_description};
  my $deadline = $form->params->{bet_deadline};
  my $eventdate = $form->params->{bet_decisive};  
  my $category = $form->params->{bet_category};
  my $side_one = $form->params->{bet_side_one};
  my $side_two = $form->params->{bet_side_two};
  my $othercurrency;
  if ($currency == 1){
  $othercurrency = 2;
  }else{
  $othercurrency = 1;
  }

    # Create bet
    my $bet = $c->user->bets->create({
      type => 1,
      currency_serial => $currency,
      title => $title,
      description => $description,
      deadline => $deadline,
      challenged_at => $eventdate,
      category => $category,
      side_one => $side_one,
      side_two => $side_two,
      created_at => DateTime->now( time_zone => 'local' ),
    });
    
    # Create bet for the other currency
    my $betother = $c->user->bets->create({
      type => 1,
      currency_serial => $othercurrency,
      title => $title,
      description => $description,
      deadline => $deadline,
      challenged_at => $eventdate,
      category => $category,
      side_one => $side_one,
      side_two => $side_two,
      created_at => DateTime->now( time_zone => 'local' ),
    });
    
    
  if($currency == 1){ 
  push @{$c->flash->{messages}}, "Your bitcoin game of foresight event has been started.";
  }elsif($currency == 2){push @{$c->flash->{messages}}, "Your namecoin game of foresight event has been started.";}  
    
  $c->res->redirect(
      $c->uri_for('/bet/' . $bet->serial . '/view')
    );
  }
}

 sub skill :Path('/bet/skill') :FormConfig CaptureArgs(1) { 
  my ( $self, $c, $currency) = @_;
  my $form = $c->stash->{form};

  if($currency eq 'bitcoin'){
  $currency = 1;
  }elsif($currency eq 'namecoin'){
  $currency = 2;
  }elsif($currency == undef){
    $c->res->redirect(
      $c->uri_for('/bets')
    );
    $currency = 1;
  }else{
      $c->res->redirect(
      $c->uri_for('/bets')
    );
    $currency = 1;
  }
    my $balance = $c->user->balances->search({currency_serial => $currency })->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => $currency  });
    $balance->amount(0);
    $balance->update();
  }

  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = floor($balance->amount * 100) / 100;
 
  if ($form->submitted_and_valid) {

  my $amount = $form->params->{amount};
  my $title = $form->params->{bet_title};
  my $description = $form->params->{bet_description};
  my $category = $form->params->{bet_category};
  my $conditions = $form->params->{bet_conditions};

    if ( ($balance->amount * 100) < $amount || $amount < 0.01 || int($amount * 100) < $amount)  {
      $form->get_field("amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }

    $balance->amount(
      $balance->amount() - ( $amount / 100 )
    );
    $balance->update();
 
    # Create bet
    my $bet = $c->user->bets->create({
      type => 2,
      currency_serial => $currency,
      amount => $amount,
      title => $title,
      description => $description,
      category => $category,
      deadline => DateTime->now( time_zone => 'local' ),
      conditions => $conditions,
      created_at => DateTime->now( time_zone => 'local' ),
    });
    
  $c->res->redirect(
      $c->uri_for('/bets')
    );
    
   push @{$c->flash->{messages}}, "Your bet is placed and the coins have been placed in escrow.";
  }
}

sub view_bet : Chained('base') PathPart('view') Args(0) :FormConfig{
  my ($self, $c) = @_;
  my $form = $c->stash->{form};
  my $bet = $c->stash->{bet};
  
  $c->stash(
     template => 'bets/view_bet',
     bet       => $bet,
   );
      
     if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{

      $c->stash->{bet_comments} = $c->model("PokerNetwork::Comments")->search({ 
     bet_serial => $bet->serial}, {order_by => { 
        -asc => 'created_at' } });


     $c->stash->{userbets_s_one} = $c->model("PokerNetwork::User2bet")->search({ 
     bet_serial => $bet->serial,
     side => 1,}, {order_by => { 
        -desc => 'created_at' } });
  
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
     
  my $balance = $c->user->balances->search({currency_serial => $bet->currency_serial })->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => $bet->currency_serial  });
    $balance->amount(0);
    $balance->update();
  }

     $c->stash->{balance} = $balance;
     $c->stash->{current_balance} = floor($balance->amount * 100) / 100;
     
 if ($form->submitted_and_valid and $bet->type == 1 and $bet->deadline_passed == 0 ){
     
      my $amount = $form->params->{amount};
      my $side = $form->params->{side};


    if ( ($balance->amount * 100) < $amount || $amount < 0.01  || int($amount * 100) < $amount  )  {
      $form->get_field("amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    };

  if( $c->stash->{deadline_passed} == 0 ){
  
    $balance->amount(
      $balance->amount() - ( $amount / 100 )
    );
    $balance->update();
    
    #Add amount to total for tracking purposes
    $bet->amount( $bet->amount + $amount );
    $bet->update();
    
    # Create bet
    my $userbet = $c->user->userbets->create({
      bet_serial => $bet->serial,
      amount => $amount,
      side => $side,
      created_at => DateTime->now( time_zone => 'local' ),
    });
    
     push @{$c->flash->{messages}}, "You have placed a bet on side " . $side . " for " . $amount . " mooncoins.";
}
       $c->res->redirect(
      $c->uri_for('/bet/' . $bet->serial . '/view')
    );
     }
   }  
 }
 
 
sub delete :Chained('base') :PathPart('delete') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  
   if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{

  my $userbet = $bet->userbets->first;
  if($bet->type == 2){
  
  if($c->user->serial == $c->stash->{bet}->user_serial and $c->stash->{bet}->challenger_serial == NULL ){
  
  my $balance = $c->user->balances->search({currency_serial => $bet->currency_serial, })->first;

   if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => $bet->currency_serial, });
    $balance->amount(0);
    $balance->update();
  }

  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = floor($balance->amount * 100) / 100;  
    
  my $dd = $c->stash->{bet};
  my $amount = $c->stash->{bet}->amount;

    $balance->amount(
      $balance->amount() + ( $amount / 100 )
    );
    $balance->update();
  
  $dd->delete;
 
  push @{$c->flash->{messages}}, "Your bet has been canceled and your coins has been returned.";
  };  
  $c->res->redirect(
      $c->uri_for('/bets')
    );
    }elsif($bet->type == 1 and $userbet == undef ){
    

    $bet->delete;
 
    push @{$c->flash->{messages}}, "The event has been deleted.";
    $c->res->redirect(
      $c->uri_for('/bets')
    );
}else{
push @{$c->flash->{messages}}, "A bet has been placed on this event, therefore it can no longer be deleted.";

      $c->res->redirect(
      $c->uri_for('/bets')
    );}
    
}

sub challenge :Chained('base') :PathPart('challenge') {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet}; 
  
   if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{
   my $balance = $c->user->balances->search({currency_serial => $bet->currency_serial,})->first;
   my $amount = $c->stash->{bet}->amount;
   
   if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => $bet->currency_serial, });
    $balance->amount(0);
    $balance->update();
  }
  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = floor($balance->amount * 100) / 100;
  if($balance->amount < ( $amount / 100 )){
  
  push @{$c->flash->{messages}}, "You don't have enough funds to accept the challenge.";
  $c->res->redirect(
    $c->uri_for('/bet/' . $c->stash->{bet}->id . '/view')
  );
  }elsif($c->user->serial != $c->stash->{bet}->user_serial and $c->stash->{bet}->challenger_serial == NULL){
  
      $balance->amount(
      $balance->amount() - ( $amount / 100 )
    );
    $balance->update();
  
  $c->stash->{bet}->challenger_serial($c->user->serial);
  $c->stash->{bet}->challenged_at(DateTime->now( time_zone => 'local' ));
  $c->stash->{bet}->update();

  push @{$c->flash->{messages}}, "You have accepted the challenge, the coins have been put into escrow.";
  $c->res->redirect(
    $c->uri_for('/bet/' . $c->stash->{bet}->id . '/view')
  );
  }
  elsif( $c->stash->{bet}->type == 1 ){
   push @{$c->flash->{messages}}, "Wrong bet type. Your actions are being logged.";
  $c->res->redirect(
    $c->uri_for('/bet/' . $c->stash->{bet}->id . '/view')
  );

  }else {
  push @{$c->flash->{messages}}, "This bet already has a challenger.";
  $c->res->redirect(
    $c->uri_for('/bet/' . $c->stash->{bet}->id . '/view')
  );
  };
  }
}
}

sub comment :Chained('base') :PathPart('comment') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
   if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{
       if($bet->type == 2 and ($c->user->serial != $bet->user_serial and $c->user->serial != $bet->challenger_serial)){
      push @{$c->flash->{messages}}, "You must be a participant to comment on this type.";
    $c->res->redirect($c->uri_for('/bet/' . $c->stash->{bet}->id . '/view'));
  }
  my $form = $c->stash->{form};
  my $comment = $form->params->{comment};
  
  if ($form->submitted_and_valid) {
  # Create comment
  my $comment = $c->stash->{bet}->comments->create({
      created_at => DateTime->now( time_zone => 'local' ),
      bet_serial => $c->stash->{bet}->serial,
      user_serial => $c->user->serial,
      comment => $comment,
    });
    push @{$c->flash->{messages}}, "You have published a comment.";
    $c->res->redirect($c->uri_for('/bet/' . $c->stash->{bet}->id . '/view'));
  };   
  }
}

sub comment_edit :Chained('base') :PathPart('editcom') :Args(1) :FormConfig{
  my ($self, $c, $id) = @_;
  	  my $bet = $c->stash->{bet};
    
      $c->stash->{comment} = $c->model("PokerNetwork::Comments")->search({serial => $id})->first;

     my $form = $c->stash->{form};

     
     $form->get_field({name => 'comment'})->default(
    $c->stash->{comment}->comment
  );
     
 if ($form->submitted_and_valid) {
  
  $c->stash->{comment}->comment(
    $form->params->{comment}
  );
  
    $c->stash->{comment}->update();
  
  push @{$c->flash->{messages}}, "This comment has been edited.";
  $c->res->redirect($c->uri_for('/bet/' . $c->stash->{bet}->id . '/view'));
  }
}

sub status :Chained('base') :PathPart('status') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
   if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{

  if($c->stash->{bet}->type == 2){
  if($c->user->serial != $c->stash->{bet}->challenger_serial and $c->user->serial != $c->stash->{bet}->user_serial){
  $c->res->redirect(
  $c->uri_for('/bet/' . $c->stash->{bet}->id . '/view')
  );
  }
  
  my $form = $c->stash->{form};
  
  if ($form->submitted_and_valid) {
  my $status = $form->params->{bet_status_update};
  ## Game of skill update
  if( $c->stash->{bet}->challenger_serial != NULL and $c->stash->{bet}->type == 2){
     if( $c->user->serial == $c->stash->{bet}->user_serial and $c->stash->{bet}->user_status == NULL){
       $c->stash->{bet}->user_status($status);
 	   $c->stash->{bet}->u_status_at(DateTime->now( time_zone => 'local' ));
  	   $c->stash->{bet}->update();
  	   push @{$c->flash->{messages}}, "You have updated your status in this game.";
     }
     elsif( $c->user->serial == $c->stash->{bet}->challenger_serial and $c->stash->{bet}->challenger_status == NULL){
       $c->stash->{bet}->challenger_status($status);
 	   $c->stash->{bet}->c_status_at(DateTime->now( time_zone => 'local' ));
  	   $c->stash->{bet}->update();
  	   push @{$c->flash->{messages}}, "You have updated your status in this game.";
     }else{push @{$c->flash->{messages}}, "Your status was NOT updated.";};
  }
  else{push @{$c->flash->{messages}}, "Your status was NOT updated.";};  
  $c->res->redirect($c->uri_for('/bet/' . $c->stash->{bet}->id . '/view'));
  };
  }
  }
}


sub report :Chained('base') :PathPart('report') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet}; 
   if ( $c->stash->{bet} == undef ){
         $c->res->redirect(
      $c->uri_for('/bets')
    );
     }else{

  my $form = $c->stash->{form};
  my $title = $form->params->{report_title};
  my $description = $form->params->{report_description};
  
  if ($form->submitted_and_valid) {
  # Create report
  my $report = $c->stash->{bet}->report->create({
      created_at => DateTime->now( time_zone => 'local' ),
      bet_serial => $c->stash->{bet}->serial,
      user_serial => $c->user->serial,
      title => $title,
      description => $description,
    });
    
        # This is ugly. Need to refactor somehow later
    my $message = "Report Message: ". $description;

    $c->log->debug($message);

    $c->email(
        header => [
            From    => $c->config->{site_email},
            To      => $c->config->{site_email},
            Subject => 'Bet Report: ' . $title,
        ],
        body => $message,
    );  
        
    push @{$c->flash->{messages}}, "You have reported an issue regarding this bet.";
    $c->res->redirect($c->uri_for('/bet/' . $c->stash->{bet}->id . '/view'));
  };
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
