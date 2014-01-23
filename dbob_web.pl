#!/usr/bin/env perl

use utf8;
use DBI;
use Encode qw(encode decode);
use DateTime;
use LWP::UserAgent;
use Data::Printer;
use Mojo::UserAgent;

use Mojolicious::Lite;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

my $config = plugin 'Config';

my $DBH = DBI->connect (
    'dbi:mysql:dbob',
    "$ENV{DB_ID}",
    "$ENV{DB_PW}",
    {
        RaiseError        => 1,
        AutoCommit        => 1,
        mysql_enable_utf8 => 1,
        mysql_auto_reconnect => 1,
    },
);

get '/' => sub {
    my $self = shift;
    
} => 'stlish';

get '/graph' => sub {
    my $self = shift;

    my $sth = $DBH->prepare(qq{ SELECT id, menu, cnt FROM menu_cnt });
    $sth->execute();

    my %menus;
    while ( my @row = $sth->fetchrow_array ) {
        my ( $id, $menu, $score ) = @row;

        $menus{$id} = {
            menu    =>  $menu,
            score   =>  $score,
        };
    }

    $self->stash( menus => \%menus );
    
} => 'graph';

get '/table' => sub {
    my $self = shift;

    my $sth = $DBH->prepare(qq{ SELECT id, menu, cnt FROM menu_cnt });
    $sth->execute();

    my %menus;
    while ( my @row = $sth->fetchrow_array ) {
        my ( $id, $menu, $score ) = @row;

        $menus{$id} = {
            menu    =>  $menu,
            score   =>  $score,
        };
    }

    $self->stash( menus => \%menus );
    
} => 'table';

get '/misskang' => sub {
    my $self = shift;
    
} => 'misskang';

app->start;
