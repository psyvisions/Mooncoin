package Room::Controller::Arbitration::Bets;
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

Room::Controller::Arbitration::Reports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

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
  
  my @categories;
  my @types;
  my $section;
  foreach $section( $c->user->sections) {
    if($section->deposit == 1){
    push(@categories, $section->category);
    push(@types, $section->type);
    }
  }
 
  $c->stash->{bets} = $c->model("PokerNetwork::Bets")->search({
  active => undef,
  category => [@categories],
  type => [@types],
  }, { 
      rows => 50,
      page => $page,
      order_by => { 
        -asc => 'created_at' 
      } 
  });
}
   
sub view_bet :Chained('bet_base') :PathPart('view') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};  
     $c->stash->{bet_comments} = $c->model("PokerNetwork::Comments")->search({ 
     bet_serial => $bet->serial}, {order_by => { 
        -asc => 'created_at' } });

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
  my $amount = $amount * 2;
 
  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;

  $u_balance->amount(
    $u_balance->amount() + ( $amount_due / 100 )
  );
  $u_balance->update();
  #active 2 is side 1 - confusing but helps record wins easier
  $c->stash->{bet}->active('2');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
   push @{$c->stash->{messages}}, "Author Won!";
  }
  elsif( $bet->user_status == '2' and $bet->challenger_status == '1' ){
  my $amount = $amount * 2;
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;
  
  $c_balance->amount(
  $c_balance->amount() + ( $amount_due / 100 )
  );
  $c_balance->update();
  #active 3 is side 2 - confusing but helps record wins easier
  $c->stash->{bet}->active('3');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  push @{$c->stash->{messages}}, "Challenger Won!";
  }
  elsif($bet->user_status == '3' and $bet->challenger_status == '3'){
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;
  
  $c_balance->amount(
    $c_balance->amount() + ( $amount_due / 100 )
  );
  $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;

  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;

  $u_balance->amount(
    $u_balance->amount() + ( $amount_due / 100 )
  );
  $u_balance->update();
  #active 4 is draw - confusing but helps record wins easier
  $c->stash->{bet}->active('4');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
    
  push @{$c->stash->{messages}}, "Draw";
  
  }
  else{
  push @{$c->stash->{messages}}, "Can't determine conclusion.";
  }
  
   my $arb_assign = $c->model('PokerNetwork::Arb2section')->search({user_serial => $c->user->serial, category => $bet->category, type => $bet->type,})->first;
    
	my $arb_share = $arb_assign->percentage / 100;
	my $arb_reward = $fees * $arb_share; 
	
    my $arb_balance = $c->user->balances->search({currency_serial => $bet->currency_serial })->first;
    
    $arb_balance->amount(
      $arb_balance->amount() + ( $arb_reward / 100 ) #covert from mooncoins
    );
    $arb_balance->update();
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bets')
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
  if ($form->submitted_and_valid and $bet->active == undef) {
  
  my $result = $form->params->{bet_choose_winner};

  if($result == 1){
    
  foreach $userbet( $bet->userbets ) { 
   my $ratio = $bet->get_ratio; 
   my $h_side = $bet->get_h_side;
   my $amount = $userbet->amount;
   my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;
   
   if($userbet->side == 1){
    
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
  #active 2 is side 1 - confusing but helps record wins easier
  $c->stash->{bet}->active('2');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
   push @{$c->stash->{messages}}, "Side One wins!" . $result;
    
    $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
    );

  }elsif($result == 2){
  
  foreach $userbet( $bet->userbets ) { 
   my $ratio = $bet->get_ratio; 
   my $h_side = $bet->get_h_side;
   my $amount = $userbet->amount;
   my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;

   if($userbet->side == 2){
    
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
   #active 3 is side 2 - confusing but helps record wins easier
  $c->stash->{bet}->active('3');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
   push @{$c->stash->{messages}}, "Side 2 wins ! " . $result;
    
    $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
    );

  ## Draw
  }elsif($result == 3){
  my $fees;
  my $amount_due;
  
    foreach $userbet($bet->userbets) { 
    my $amount = $userbet->amount;
    my $balance = $userbet->user->balances->search({currency_serial => $bet->currency_serial })->first;
    
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
    
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    
    $balance->update();
    }
     #active 4 is draw - confusing but helps record wins easier
    $c->stash->{bet}->active('4');
    $c->stash->{bet}->finished_at(DateTime->now);
    $c->stash->{bet}->update();
    
    push @{$c->stash->{messages}}, "Draw, everyone received their funds.";
    
    $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
    );   
  }
      my $arb_assign = $c->model('PokerNetwork::Arb2section')->search({user_serial => $c->user->serial, category => $bet->category, type => $bet->type,})->first;
    
	my $arb_share = $arb_assign->percentage / 100;
	my $arb_reward = $fees * $arb_share; 
	
    my $arb_balance = $c->user->balances->search({currency_serial => $bet->currency_serial })->first;
    
    $arb_balance->amount(
      $arb_balance->amount() + ( $arb_reward / 100 ) #covert from mooncoins
    );
    $arb_balance->update();
 } 
}

sub choose :Chained('bet_base') :PathPart('choose') :FormConfig{
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  my $form = $c->stash->{form};
  my $fees;
  my $amount_due;
   if($bet->active != undef){
   push @{$c->stash->{messages}}, "You already concluded this bet. Please don't try to process a bet twice.";
   $c->res->redirect(
   $c->uri_for('/user/arbitrator/bets')
   );}
  if( $bet->type == 2){
  
  if ($form->submitted_and_valid and $bet->active == undef) {
  my $result = $form->params->{bet_choose_winner};
  
  ## Game of skill update
  my $amount = $c->stash->{bet}->amount;
  
  if( $result == '1' ){
  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;
  my $amount = $amount * 2;

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
   push @{$c->stash->{messages}}, "Author Won!";
  }
  elsif( $result == '2' ){
  my $amount = $amount * 2;
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
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
  push @{$c->stash->{messages}}, "Challenger Won!";
  }
  elsif( $result == '3' ){
  my $c_balance = $c->stash->{bet}->challenger->balances->search({currency_serial => $bet->currency_serial})->first;
  
  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;
  
  $c_balance->amount(
    $c_balance->amount() + ( $amount_due / 100 )
  );
  $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;

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
    
  push @{$c->stash->{messages}}, "Draw";
  }
  else{
  push @{$c->stash->{messages}}, "Can't determine conclusion.";
  }
  
  my $arb_assign = $c->model('PokerNetwork::Arb2section')->search({user_serial => $c->user->serial, category => $bet->category, type => $bet->type,})->first;
    
  my $arb_share = $arb_assign->percentage / 100;
  my $arb_reward = $fees * $arb_share; 
	
  my $arb_balance = $c->user->balances->search({currency_serial => $bet->currency_serial })->first;
    
  $arb_balance->amount(
    $arb_balance->amount() + ( $arb_reward / 100 ) #covert from mooncoins
  );
  $arb_balance->update();
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
    );
  }  }else{
  push @{$c->stash->{messages}}, "Wrong bet type.";
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
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
  
  $fees = $amount * 0.01;
  $amount_due = $amount - $fees;
  
  $c_balance->amount(
    $c_balance->amount() + ( $amount_due / 100 )
  );
  $c_balance->update();

  my $u_balance = $c->stash->{bet}->user->balances->search({currency_serial => $bet->currency_serial})->first;

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
    
    $fees = $amount * 0.01;
    $amount_due = $amount - $fees;
    $balance->amount(
      $balance->amount() + ( $amount_due / 100 )
    );
    $balance->update();
    $userbet->delete;
    
    }
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/reports')
    );   
  }
  
  $bet->delete;

  push @{$c->stash->{messages}}, "The bet has been cancelled and the coins have been returned." ;
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bets')
    );     
}

sub bet_freeze :Chained('bet_base') :PathPart('freeze') :Args(0) {
  my ($self, $c) = @_;
  my $bet = $c->stash->{bet};
  $c->stash->{bet}->active('1');
  $c->stash->{bet}->finished_at(DateTime->now);
  $c->stash->{bet}->update();
  
  push @{$c->stash->{messages}}, "This bet has been cancelled and a the coins have been frozen.";
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $bet->serial . '/view')
    );
}

sub bet_edit :Chained('bet_base') :PathPart('edit') :Args(0) :FormConfig {
  my ( $self, $c ) = @_;
  my $bet = $c->stash->{bet};
  my $form = $c->stash->{form};
  
  $form->get_field({name => 'title'})->default(
    $c->stash->{bet}->title
  );
  
  $form->get_field({name => 'description'})->default(
    $c->stash->{bet}->description
  );
  
  if($bet->type == 2){
  $form->get_field({name => 'conditions'})->default(
    $c->stash->{bet}->conditions
  );
  }elsif($bet->type == 1){
  $form->get_field({name => 'bet_decisive'})->default(
    $c->stash->{bet}->challenged_at
  );
  $form->get_field({name => 'bet_deadline'})->default(
    $c->stash->{bet}->deadline
  );
  $form->get_field({name => 'bet_side_one'})->default(
    $c->stash->{bet}->side_one
  );
  $form->get_field({name => 'bet_side_two'})->default(
    $c->stash->{bet}->side_two
  );
  }
  
  # If 'Cancel' button pressed - redirect to /user page
  if ($c->req->param('cancel')) {
    $c->res->redirect(
      $c->uri_for('/user')
    );
  }

  if ($form->submitted_and_valid) {
  
    $c->stash->{bet}->title(
      $form->params->{title}
    );
    
    $c->stash->{bet}->description(
      $form->params->{description}
    );
    
   $c->stash->{bet}->update();
  
    push @{$c->stash->{messages}}, "This bet has been edited.";
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $c->stash->{bet}->serial . '/view')
    );
  }
}  

##Delete Comment
sub comment_delete :Chained('bet_base') :PathPart('delcom') :Args(1) {
  my ($self, $c, $id) = @_;  
  my $bet = $c->stash->{bet};
    
  $c->stash->{comment} = $c->model("PokerNetwork::Comments")->search({serial => $id})->first;
  $c->stash->{comment}->delete;
  
  push @{$c->stash->{messages}}, "This comment has been deleted.";
  
  $c->res->redirect(
      $c->uri_for('/user/arbitrator/bet/' . $c->stash->{bet}->serial . '/view')
    );
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