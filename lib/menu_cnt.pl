#!/usr/bin/env perl 

use strict;
use warnings;

use DBI;
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TokeParser::Simple;
use Encode qw(encode decode);
use Net::Twitter::Lite;
use Data::Printer;
binmode(STDOUT, ":utf8");

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

my (@row, @menus, @new_row);
my %count;

my $sth = $DBH->prepare(qq{ SELECT menu FROM week_menu });
$sth->execute();

while ( @row = $sth->fetchrow_array ) {
    push @new_row, grep ( /[^0 kcal]/, @row);
}

@new_row = grep { s/(\d+.\d+\skcal$)//g } @new_row;

foreach my $str ( @new_row ) {
    push @menus, (split / /, $str);
}

@menus = grep { $_  ne "" } @menus;

foreach my $b_menu ( @menus ) {
    $count{$b_menu}++;
}

$sth = $DBH->prepare(qq{ INSERT INTO `menu_cnt` (`menu`, `cnt`) VALUES (?,?) });

foreach my $a_menu ( sort keys %count ) {
    $sth->execute( $a_menu, $count{$a_menu} );
}
