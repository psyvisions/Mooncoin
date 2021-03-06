package Room::Controller::User;
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

sub auto :Private {
  my ($self, $c) = @_;

  if (!$c->user && $c->action->private_path !~ /user\/(login|register|forgot_password|reset_password|no_avatar)/) {
    $c->res->redirect(
      $c->uri_for('/user/login', '', {'destination' => $c->action,})
    );

    return;
  }

  1;
}


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;
  
  ##Initialize bitcoins  
  my $btc_balance = $c->user->balances->search({currency_serial => 1})->first;

  if (! $btc_balance) {
    $btc_balance = $c->user->balances->find_or_create({ currency_serial => 1 });
    $btc_balance->amount(0);
    $btc_balance->update();
  }
  ##Initialize namecoins
    my $nmc_balance = $c->user->balances->search({currency_serial => 2})->first;

  if (! $nmc_balance) {
    $nmc_balance = $c->user->balances->find_or_create({ currency_serial => 2 });
    $nmc_balance->amount(0);
    $nmc_balance->update();
  }
  
  my $slc_balance = $c->user->balances->search({currency_serial => 3})->first;
  if (! $slc_balance) {
    $slc_balance = $c->user->balances->find_or_create({ currency_serial => 3 });
    $slc_balance->amount(0);
    $slc_balance->update();
  }
  
}

sub profile :Local :CaptureArgs(1) {
  my ($self, $c, $user_id) = @_;
  
  $c->stash->{user} = $c->model("PokerNetwork::Users")->find($user_id);
}

sub user_view :Chained('profile') :PathPart('profile') :Args(0) {
  my ($self, $c) = @_;

}

sub login :Local :Args(0) :FormConfig {
    my ( $self, $c ) = @_;

    if ($c->user) {
      $c->response->redirect(
        $c->uri_for('/user')
      );
    }
    
    my $form = $c->stash->{form};

    if ($form->submitted_and_valid) {
    
      my $user = $c->authenticate({
                    name => $form->params->{name},
                    password => $form->params->{password},
                 });

      if ($user) {
        if ($c->req->param('destination')) {
          $c->res->redirect(
            $c->req->param('destination')
          );

          return 1;
        }

        $c->res->redirect(
          $c->uri_for('/user')
          
        );
      }
      else {
        push @{$c->stash->{errors}}, "Invalid Username or Password.";
      }
    }
}


sub logout :Local :Args(0) {
  my ( $self, $c ) = @_;

  $c->logout;
  
  $c->model("PokerNetwork")->logout(
    $c->session->{pokernetwork_auth}
  );

  push @{$c->stash->{messages}}, "Logged out. Good bye.";
  $c->res->redirect(
    $c->uri_for('/')
  );
}

sub register :Local :Args(0) :FormConfig {
  my ( $self, $c ) = @_;

  if ($c->user) {
    $c->response->redirect(
      $c->uri_for('/user')
    );
  }
  my $form = $c->stash->{form};
  if ($form->submitted_and_valid) {
    if (
          $c->model("PokerNetwork::Users")->search({ name => $form->params->{name} })->count > 0
       ) {
      $form->get_field("name")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }
    if (
          $form->params->{email} ne '' &&
          $c->model("PokerNetwork::Users")->search({ email => $form->params->{email} })->count > 0
    ) {
      $form->get_field("email")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }
    my $user = $c->model("PokerNetwork::Users")->new({
      name => $form->params->{name},
      password => $form->params->{password},
      created => DateTime->now,
    });

    if ( $form->params->{email} ) {
      $user->email( $form->params->{email} );
    }
    $user->insert();
    push @{$c->stash->{messages}}, "Account successfully created. Please, login with your details.";
    $c->res->redirect(
      $c->uri_for('/user/login')
    );
  }
}

sub forgot_password :Local :Args(0) :FormConfig {
  my ($self, $c) = @_;

  if ($c->user) {
    $c->response->redirect(
      $c->uri_for('/user')
    );
  }

  my $form = $c->stash->{form};

  if ($form->submitted_and_valid) {
    my $user = $c->model("PokerNetwork::Users")->search({ email => $form->params->{email} })->first;

    if (! $user) {
      $form->get_field("email")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }

    my $gen = new String::Random;
    my $key = unpack('h*', $gen->randpattern('b'x10));

    $user->request_password($key);
    $user->update();

    # This is ugly. Need to refactor somehow later
    my $message = "Someone requested to reset your password at ". $c->uri_for('/') ."\n\nYour username: ". $user->name ."\n\nTo reset password, please open (or copy/paste) this URL: ". $c->uri_for('/user/reset_password', $user->id, $key) ."\n\nIf this was not you, just ignore this email.";

    $c->log->debug($message);

    $c->email(
        header => [
            From    => $c->config->{site_email},
            To      => $user->email,
            Subject => 'Password reset link.'
        ],
        body => $message,
    );

    $c->stash->{email} = $user->email;
  }
}

sub reset_password :Local :Args(2) :FormConfig {
  my ($self, $c, $id, $key) = @_;

  my $user = $c->model("PokerNetwork::Users")->find($id);
  
  if (!defined($user) || !defined($user->request_password) || $user->request_password ne $key) {
    $c->detach( '/default' );
  }

  my $form = $c->stash->{form};

  if ($form->submitted_and_valid) {
    $user->password( $form->params->{password} );
    $user->update();
    
    push @{$c->stash->{messages}}, "Password successfully reset.";

    $c->res->redirect(
      $c->uri_for('/user/login')
    );
  }
}

sub edit :Local :Args(0) :FormConfig {
  my ( $self, $c ) = @_;

  my $form = $c->stash->{form};
  
  $form->get_field({ name => 'email' })->default(
    $c->user->email
  );

  $form->get_field({name => 'hide_gravatar'})->default(
    $c->user->hide_gravatar
  );

  $form->get_field({name => 'emergency_address'})->default(
    $c->user->emergency_address
  );
  
  $form->get_field({name => 'emergency_nmc_address'})->default(
    $c->user->emergency_nmc_address
  );
  
  $form->get_field({name => 'emergency_slc_address'})->default(
    $c->user->emergency_slc_address
  );


  # If 'Cancel' button pressed - redirect to /user page
  if ($c->req->param('cancel')) {
    $c->res->redirect(
      $c->uri_for('/user')
    );
  }

  if ($form->submitted_and_valid) {

    if (! $c->user->check_password( $form->params->{old_password} )) {
      $form->get_field("old_password")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }
    
    if ($form->params->{email} ne '' or $form->params->{email} != undef) {
      my $user_rs = $c->model("PokerNetwork::Users")->search({
        email => $form->params->{email},
        -not => {
          serial => $c->user->serial()
        },
      });
      
      if ( $user_rs->count() > 0 ) {
        $form->get_field("email")->get_constraint({ type => "Callback" })->force_errors(1);
        $form->process();
        return;
      }
        
    $c->user->email(
      $form->params->{email}
    );
	}
	
    if ($form->params->{password} ne '') {
      $c->user->password(
        $form->params->{password}
      );
    }

    $c->user->hide_gravatar( $form->params->{hide_gravatar} );
    $c->user->emergency_address( $form->params->{emergency_address} );
    $c->user->emergency_nmc_address( $form->params->{emergency_nmc_address} );
    $c->user->emergency_slc_address( $form->params->{emergency_slc_address} );

    $c->user->update();
    $c->user->make_column_dirty('data');

    push @{$c->stash->{messages}}, "Account successfully updated.";

    $c->res->redirect(
      $c->uri_for('/user')
    );
  }
}

sub deposit :Local { }

sub deposit_bitcoin :Path('deposit/bitcoin') {
  my ( $self, $c ) = @_;
  $c->forward('deposit_bitcoin_refresh');
  $c->stash->{bitcoin_address} = $c->user->bitcoin_address;
  $c->stash->{bitcoins_sent} = $c->user->bitcoins_received || 0;
}

sub deposit_namecoin :Path('deposit/namecoin') {
  my ( $self, $c ) = @_;
  $c->forward('deposit_namecoin_refresh');
  $c->stash->{namecoin_address} = $c->user->namecoin_address;
  $c->stash->{namecoins_sent} = $c->user->namecoins_received || 0;
}

sub deposit_solidcoin :Path('deposit/solidcoin') {
  my ( $self, $c ) = @_;
  $c->forward('deposit_solidcoin_refresh');
  $c->stash->{solidcoin_address} = $c->user->solidcoin_address;
  $c->stash->{solidcoins_sent} = $c->user->solidcoins_received || 0;
  
      my $slc_balance = $c->user->balances->search({currency_serial => 3})->first;

  if (! $slc_balance) {
    $slc_balance = $c->user->balances->find_or_create({ currency_serial => 3 });
    $slc_balance->amount(0);
    $slc_balance->update();
  }
  
}

sub deposit_bitcoin_refresh :Private {
  my ( $self, $c ) = @_;

  if (! $c->user->bitcoin_address) {
    $c->user->bitcoin_address(
      $c->model("BitcoinServer")->get_new_address()
    );
    
    $c->user->update();
  }

  my $bitcoins_new_balance = $c->model("BitcoinServer")->get_received_by_address( $c->user->bitcoin_address );

  if ($bitcoins_new_balance > $c->user->bitcoins_received) {
    my $diff = $bitcoins_new_balance - $c->user->bitcoins_received;
    $c->user->bitcoins_received(
   $c->user->bitcoins_received + $diff
    );

    $c->user->update;

    $c->user->deposits->create({
      currency_serial => 1,
      amount => $diff,
      processed => 1,
      info => $c->user->bitcoin_address,
      created_at => DateTime->now,
      processed_at => DateTime->now,
    });

    my $balance = $c->user->balances->find_or_create({ currency_serial => 1 });
    $balance->amount( $balance->amount + $diff );
    $balance->update();
  }
}

sub deposit_namecoin_refresh :Private {
  my ( $self, $c ) = @_;

  if (! $c->user->namecoin_address) {
    $c->user->namecoin_address(
      $c->model("NamecoinServer")->get_new_address()
    );
    
    $c->user->update();
  }

  my $namecoins_new_balance = $c->model("NamecoinServer")->get_received_by_address( $c->user->namecoin_address );

  if ($namecoins_new_balance > $c->user->namecoins_received) {
    my $diff = $namecoins_new_balance - $c->user->namecoins_received;
    $c->user->namecoins_received(
      $c->user->namecoins_received + $diff
    );

    $c->user->update;

    $c->user->deposits->create({
      currency_serial => 2,
      amount => $diff,
      processed => 1,
      info => $c->user->namecoin_address,
      created_at => DateTime->now,
      processed_at => DateTime->now,
    });

    my $balance = $c->user->balances->find_or_create({ currency_serial => 2 });
    $balance->amount( $balance->amount + $diff );
    $balance->update();
  }
}

sub deposit_solidcoin_refresh :Private {
  my ( $self, $c ) = @_;

  if (! $c->user->solidcoin_address) {
    $c->user->solidcoin_address(
      $c->model("SolidcoinServer")->get_new_address()
    );
    $c->user->update();
  }

  my $solidcoins_new_balance = $c->model("SolidcoinServer")->get_received_by_address( $c->user->solidcoin_address );

  if ($solidcoins_new_balance > $c->user->solidcoins_received) {
    my $diff = $solidcoins_new_balance - $c->user->solidcoins_received;
    $c->user->solidcoins_received(
      $c->user->solidcoins_received + $diff
    );

    $c->user->update;

    $c->user->deposits->create({
      currency_serial => 3,
      amount => $diff,
      processed => 1,
      info => $c->user->solidcoin_address,
      created_at => DateTime->now,
      processed_at => DateTime->now,
    });

    my $balance = $c->user->balances->find_or_create({ currency_serial => 3 });
    $balance->amount( $balance->amount + $diff );
    $balance->update();
  }
}

sub withdraw :Local { }

sub withdraw_bitcoin :Path('withdraw/bitcoin') :FormConfig {
  my ($self, $c) = @_;
  my $form = $c->stash->{form};
  my $balance = $c->user->balances->search({currency_serial => 1})->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => 1 });
    $balance->amount(0);
    $balance->update();
  }

  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = $balance->amount;

  if ($form->submitted_and_valid) {
    my $address = $form->params->{bitcoin_address};
    my $amount = $form->params->{amount};

    if ($balance->amount < $amount || $amount < 0.0100 || int($amount * 100) / 100 < $amount)  {
      $form->get_field("amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }

    $balance->amount(
      $balance->amount() - $amount
    );
    $balance->update();

	my $result;
    if( $c->user->privilege != 3 or $c->user->privilege != 999 ){
    $result = $c->model("BitcoinServer")->send_to_address($address, $amount);   
    }
    
    # Create withdrawal record for tracking purposes.
    my $withdrawal = $c->user->withdrawals->create({
      currency_serial => 1,
      amount => $amount,
      dest => $address,
      info => "Result: ". $result ."\n\nError: ". Dumper($c->model('BitcoinServer')->api->error),
      created_at => DateTime->now,
    });

    if (! $c->model('BitcoinServer')->api->error) {
      # Mark as processed if successful
      if( $c->user->privilege != 3 or $c->user->privilege != 999 ){
      $withdrawal->processed(1);
      $withdrawal->processed_at( DateTime->now() );
      }else{$withdrawal->processed(0);}
      $withdrawal->update();
      push @{$c->stash->{messages}}, "Bitcoins sent.";
    }else{
      push @{$c->stash->{errors}}, "We received your withdrawal request and will process it ASAP. If you will not receive bitcoins in 24 hours, please contact us.";
    }
    
    $c->res->redirect(
      $c->uri_for('/user')
    );
  }
}

sub withdraw_namecoin :Path('withdraw/namecoin') :FormConfig {
  my ($self, $c) = @_;
  my $form = $c->stash->{form};
  my $balance = $c->user->balances->search({currency_serial => 2})->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => 2 });
    $balance->amount(0);
    $balance->update();
  }

  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = floor($balance->amount * 100) / 100;

  if ($form->submitted_and_valid) {
    my $address = $form->params->{namecoin_address};
    my $amount = $form->params->{amount};

    if ($balance->amount < $amount || $amount < 0.0100 || int($amount * 100) / 100 < $amount)  {
      $form->get_field("amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }

    $balance->amount(
      $balance->amount() - $amount
    );
    $balance->update();
    
	my $result;
    if( $c->user->privilege != 3 or $c->user->privilege != 999){$result = $c->model("NamecoinServer")->send_to_address($address, $amount);
	}

    # Create withdrawal record for tracking purposes.
    my $withdrawal = $c->user->withdrawals->create({
      currency_serial => 2,
      amount => $amount,
      dest => $address,
      info => "Result: ". $result ."\n\nError: ". Dumper($c->model('NamecoinServer')->api->error),
      created_at => DateTime->now,
    });

    if (! $c->model('NamecoinServer')->api->error) {
      # Mark as processed if successful

      if( $c->user->privilege != 3  or $c->user->privilege != 999){
      $withdrawal->processed(1);
      $withdrawal->processed_at( DateTime->now() );
      }else{$withdrawal->processed(0);}
      $withdrawal->update();

      push @{$c->stash->{messages}}, "Namecoins sent.";

    }
    else {
      push @{$c->stash->{errors}}, "We received your withdrawal request and will process it ASAP. If you will not receive namecoins in 24 hours, please contact us.";
    }
    
    $c->res->redirect(
      $c->uri_for('/user')
    );
  }
}

sub withdraw_solidcoin :Path('withdraw/solidcoin') :FormConfig {
  my ($self, $c) = @_;
  my $form = $c->stash->{form};
  my $balance = $c->user->balances->search({currency_serial => 3})->first;

  if (! $balance) {
    $balance = $c->user->balances->find_or_create({ currency_serial => 3 });
    $balance->amount(0);
    $balance->update();
  }

  $c->stash->{balance} = $balance;
  $c->stash->{current_balance} = floor($balance->amount * 100) / 100;

  if ($form->submitted_and_valid) {
    my $address = $form->params->{solidcoin_address};
    my $amount = $form->params->{amount};

    if ($balance->amount < $amount || $amount < 0.0100 || int($amount * 100) / 100 < $amount)  {
      $form->get_field("amount")->get_constraint({ type => "Callback" })->force_errors(1);
      $form->process();
      return;
    }
    
	$amount = $amount - 0.01;

    $balance->amount(
      $balance->amount() - $amount 
    );
    $balance->update();
    
	my $result;
    if( $c->user->privilege != 3  or $c->user->privilege != 999){$result = $c->model("SolidcoinServer")->send_to_address($address, $amount);
	}

    # Create withdrawal record for tracking purposes.
    my $withdrawal = $c->user->withdrawals->create({
      currency_serial => 3,
      amount => $amount,
      dest => $address,
      info => "Result: ". $result ."\n\nError: ". Dumper($c->model('SolidcoinServer')->api->error),
      created_at => DateTime->now,
    });

    if (! $c->model('solidcoinServer')->api->error) {
      # Mark as processed if successful

      if( $c->user->privilege != 3 or $c->user->privilege != 999 ){
      $withdrawal->processed(1);
      $withdrawal->processed_at( DateTime->now() );
      }else{$withdrawal->processed(0);}
      $withdrawal->update();

      push @{$c->stash->{messages}}, "Solidcoins sent.";

    }
    else {
      push @{$c->stash->{errors}}, "We received your withdrawal request and will process it ASAP. If you will not receive solidcoins in 24 hours, please contact us.";
    }
    
    $c->res->redirect(
      $c->uri_for('/user')
    );
  }
}

sub no_avatar :Local :Args(1) {
  my ($self, $c, $uid) = @_;

  $c->res->redirect(
    $c->uri_for("/static/css/images/jpoker_table/avatar". ($uid % 19) .".png")
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
