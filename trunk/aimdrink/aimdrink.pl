#!/usr/bin/perl
#$Id$

use Net::AIM;
use IO::Select;
use Symbol;
use Socket;
use strict;

require "userdata.pl";

my $DRINKHOST = "drink.csh.rit.edu";
my $DRINKPORT = 4242;

my ($userdata, $clientinfo);
my %session;
my ($aim,$conn);
my $s = IO::Select->new();

$userdata = Drink::read_users();

$aim = new Net::AIM;
#$aim->newconn(Screenname => 'CSH Drink', Password => 'cshdrink123');
#$aim->newconn(Screenname => 'CSH Drink2', Password => 'cshdrink123');
$aim->newconn(Screenname => 'mobilesoutherner', Password => 'carleneway');

#Handlers
$conn = $aim->getconn();
$conn->set_handler("im_in", \&on_im);
$conn->set_handler("error", \&on_error);
$conn->set_handler("eviled", \&on_warn);

my $c = -5;
while (1) {
   $aim->do_one_loop();
   read_from_sessions();

   get_drink_stats() if ($c == 0);
   $c = ($c + 1) % 1800;
}

my $frag = "";
sub read_from_sessions {
   my ($sock,@ready,$line);

   foreach $sock ( $s->can_read(1) ) {

      my ($key);
      foreach (keys(%session)) {
	 if ($session{$_}->{'socket'} == $sock) {
	    $key = $_;
	 }
      }

      my $brec = recv($sock,$line,8192,0);
      my $data;
      if (defined($brec)) {
	 if (length($line) == 0) { 
	    print "Socket dead, removing...\n";
	    sendim($key,"Socket dead. Retry :)");
	    undef $session{$key};
	    $s->remove($sock); 
	    next;
	 }

	 $data = $frag . $line;
	 my @lines = split(/\n/,$data);
	 chomp($data);
	 $frag = (substr($data,-1) ne "\n" ? pop(@lines) : "");
      }

      print "Drink> $data\n";
      sendim("$key","Drink> $data");
   }

}

sub sendim {
   my ($from,$msg) = @_;
   $aim->send_im($from,$msg);
   print "--> $from: $msg\n";
}

sub on_im {
   my ($hash,$event,$from) = @_;

   my $args = $event->{'args'};

   if ($args->[1] eq 'F') {
      handle_message($from,$args->[2]);
   }

}

sub on_error {
   my ($hash,$event,$from,$to) = @_;
   print STDERR "$from sent error code #".$event->{'args'}->[0] . "\n";
   print STDERR $event->trans($event->{'args'}->[0]) . "\n";
   print STDERR "Exiting...\n";
   exit 1;
}

sub on_warn {
   my ($hash,$event,$from) = @_;

   $aim->evil($from);
}

sub handle_message {
   my ($from,$msg) = @_;

   #Strip HTML:
   $msg =~ s/\<.*?\>//g;

   print "$from: $msg\n";
   if (defined($session{$from})) {
      if ($msg =~ /^h(e(l(p)?)?)?$/) {
	 sendim($from, "This is the AIM Drink Client. The following commands are available: \n     Status\n     Drop\nAlso feel free to type 'help <command>'");
      } elsif ($msg =~ /^h(e(l(p)?)?)?.(.*)$/i) {
	 if ($4 =~ m/^s(t(a(t(u(s)?)?)?)?)?$/i) { #help status
	    sendim($from,"<b>STATUS</b> - Display the contents of Drink: Available drinks, price, and inventory.");
	 } elsif ($4 =~ m/^d(r(o(p?)?)?)?$/i) { #help drop
	    sendim($from,"<b>DROP <NUM></b> - Drop a drink from the specified slot number.");
	 }
      } elsif ($msg =~ /^s(t(a(t(u(s)?)?)?)?)?$/i) { #status
	 get_drink_stats($session{$from}{'socket'});
	 sendim($from,$clientinfo);
      } elsif ($msg =~ /^d(r(o(p)?)?)?$/i) { #drop
	 sendim($from,"Not implemented yet.");
      } elsif ($msg =~ /^s(a(v(e)?)?)?$/i) { #save
	 Drink::write_users($userdata); 
      } elsif ($msg =~ /^i(n(f(o)?)?)?$/i) { #info
	 my $say;
	 my $data = $session{$from}{'data'};
	 foreach (keys(%{$data})) { $say .= "<b>$_</b>: " . $data->{$_}."<br>" }
	 sendim($from,$say);
      }
      
      #send($session{$from}{'socket'},$msg . "\n",0);
   }
   else {
      print "-> Creating new session for $from\n";
      #New session
      my ($sock, $dconn);

      $sock = Symbol::gensym();

      socket($sock,PF_INET,SOCK_STREAM,getprotobyname('tcp')) 
        or handle_error("Unable to create new socket: $!",1,$from);
      $dconn = connect($sock,sockaddr_in($DRINKPORT, inet_aton($DRINKHOST)));

      $session{$from} = { socket => $sock, conn => $dconn };
      $session{$from}{'data'} = $userdata->{$from};

      print "Session ($from): " . $session{$from}{'data'} ."\n";

      #Selection adding
      $s->add($sock);
      sendim($from,"\nHello, $from!\nType 'help' for help.");
   }

}

sub handle_error {
   my ($error,$errno,$from) = @_;

   print STDERR "$error";
   if (defined($from)) { sendim($from,"$error"); }
}

sub get_drink_stats {
   my ($sock) = @_;
   
   print "Fetching stats.\n";

   my $sel = new IO::Select();
   
   my $usesession = 0;
   if (defined($sock)) { $usesession = 1; }
   else { 
      $sock = Symbol::gensym(); 

      socket($sock,PF_INET,SOCK_STREAM,getprotobyname('tcp')) 
	or handle_error("Unable to create new socket: $!",1);
      connect($sock,sockaddr_in($DRINKPORT, inet_aton($DRINKHOST)))
	or return;
   }
   $sel->add($sock);

   send($sock,"stat\n",0);
   send($sock,"quit\n",0) if ($usesession != 1);
   #print "> $!\n";

   my ($ready,$line,$frag);
   my $info;
   #print "Fetching...";
   my ($brec,$data);
   while (1) {
      ($ready) = $sel->can_read(1);
      last unless (defined($ready));
      $brec = recv($ready,$line,8192,0);
      next if ($line =~ m/^OK/);
      last if (length($line) == 0);
      $data = $frag . $line;
      my @lines = split(/\n/,$data);
      $frag = (substr($data,-1) ne "\n" ? pop(@lines) : "");
      $info .= $data;
   }
   close($sock) if ($usesession == 1);

   #$info =~ s/(\r)?\n/<br>/g;

   #Prettify it.
   my @slots = split("\n",$info);
   $info = '';
   foreach (@slots) {
     my @word = split(" ",$_);
     $info .= '<b>'.$word[1].'</b>: $0.'.$word[2].' - '.$word[3].' left.<br>';
   }

   $clientinfo = $info;
   $aim->set_info($info);
}


###

sub include {
   my ($file) = @_;

   local $/ = undef;
   open(SRC,$file) or die("Unable to open $file.\n$!\n");
   eval(<SRC>);
   close(SRC);

}
