#!/home/newbcode/perl5/perlbrew/perls/perl-5.14.2/bin/perl

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

my (@after_row, @row, @menus, @new_row);
my %count;

#메뉴를 insert 하기전 존재하는 메뉴를 확인하기 위한 배열
my $sth = $DBH->prepare(qq{ SELECT menu FROM menu_cnt });
$sth->execute();

while (my @before_row = $sth->fetchrow_array ) {
    push @after_row, $before_row[0];
}

$sth = $DBH->prepare(qq{ SELECT menu FROM week_menu });
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

foreach my $chk_menu ( @menus ) {
    $sth = $DBH->prepare(qq{ UPDATE menu_cnt SET cnt=(cnt + ?) WHERE menu=?});
    #$sth = $DBH->prepare(qq{ INSERT INTO `menu_cnt` (`cnt`, `menu`) VALUES (?,?) });
    $sth->execute( $count{$chk_menu}, $chk_menu );
}

=pod
$sth = $DBH->prepare(qq{ INSERT INTO `menu_cnt` (`cnt`, `menu`) VALUES (?,?) });
foreach my $key (sort {$count{$b} <=> $count{$a};} keys %count) {
    $sth->execute( $key, $count{$key} );
}
