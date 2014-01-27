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

chomp (my $date_check = `date "+%a"`);
chomp (my $c_date = `date "+%Y-%m-%d"`);
my $html = $c_date;

my $sth = $DBH->prepare(qq{ SELECT ymd FROM week_menu WHERE ymd LIKE '%$c_date%'});
$sth->execute();
my @row = $sth->fetchrow_array;

if ( @row ) {
    print "Exsits DB...\n";
}
else {
    my $week3_url = "http://www.welstory.com/mywelstory/restaurant/weekMenu.jsp?mMode=21&sDate=$c_date&hall_no=E16I";
    my $base_url = 'http://www.welstory.com/main.jsp';
    my $login_url = "http://www.welstory.com/loginAction.do?%2Fmywelstory%2FmywelIndex.jsp&pwd_yn=Y&memId=$ENV{WES_ID}&pwd=$ENV{WES_PW}";

    my $ua = LWP::UserAgent->new;
    my $response;
    my $cookies = new HTTP::Cookies;
    $ua->cookie_jar({});
    $response = $ua->get($base_url);
    $response = $ua->get($login_url);
    $response = $ua->get($week3_url);

    if ( $response->is_success ) {
        $response = $ua->get($week3_url, ":content_file" => "menu/$html");
        my $day_p = HTML::TokeParser::Simple->new( "menu/$html" );
        my (@days, @seq_days, @foods);
        my ($first_day, $last_day);

        while ( my $td = $day_p->get_tag('td') ) {
            if ( my $td_attr = $td->get_attr('width') ) {
                if ( $td_attr == '408' ) {
                    my $text = $day_p->get_trimmed_text("/td");
                    my $d_text = decode("euc-kr", $text);
                    ($first_day, $last_day) = $d_text =~ m/.*?(\d+-\d\d-\d\d) ~ (\d+-\d+-\d+)./;
                }
                elsif ( $td_attr eq '52' ) {
                    if ( my $a_day_attr = $td->get_attr('align') ) {
                        if ( $a_day_attr eq 'center' ) {
                            my $ss_day = $day_p->get_trimmed_text("/td");
                            my $d_ss_day = decode("euc-kr", $ss_day);
                            next if $d_ss_day eq '[IMG]';
                            push @seq_days, $d_ss_day;
                        }
                    }
                }
            }
            elsif ( my $f_attr = $td->get_attr('height') ) {
                if ( $f_attr == '16' ) {
                    if ( my $f_c_attr = $td->get_attr('class') ) {
                        if ( $f_c_attr == '11' ) {
                            my $f_text = $day_p->get_trimmed_text("/td");
                            my $d_f_text = decode("euc-kr", $f_text);
                            my $d_d_f_text = encode ("utf8" , $d_f_text);
                            $d_d_f_text =~ s/ㆍ//g;
                            push @foods, $d_d_f_text;
                        }
                    }
                }
            }
        }

        my $day_cnt = 0;
        foreach my $new_date ( qw/a 1 2 3 4/ ) {
            if ( $new_date eq 'a' ) {
                push @days, "$first_day $seq_days[$day_cnt]";
            }
            else {
                my $today_date = `date -d '$first_day + $new_date day' "+%Y-%m-%d"`;
                chomp $today_date;
                push @days, "$today_date $seq_days[$day_cnt]" ;
            }
            $day_cnt++;
        }

        my @new_course = qw/korean inter snack/;
        my @new_meal = qw/아침 점심 저녁 야식/; 
        my $fooods = join(' ', @foods);
        my @meal_foods = $fooods =~ m/(.*?\d+\skcal)/g;
        my %week_menu;
        my $init_num = 0;
        my $last_num = 59;

        foreach my $todate ( @days ) {
            foreach my $course ( @new_course ) {
                my $div = $init_num % 4;
                if ( $div == 0 ) {
                    foreach my $meal ( @new_meal ) {
                        push @{ $week_menu{$todate}{$course}{$meal} ||= [] }, shift(@meal_foods);
                    }
                }
                elsif ( $div == 1 ) {
                    foreach my $meal ( @new_meal ) {
                        push @{ $week_menu{$todate}{$course}{$meal} ||= [] }, shift(@meal_foods);
                    }
                }
                elsif ( $div == 2 ) {
                    foreach my $meal ( @new_meal ) {
                        push @{ $week_menu{$todate}{$course}{$meal} ||= [] }, shift(@meal_foods);
                    }
                }
                elsif ( $div == 3 ) {
                    foreach my $meal ( @new_meal ) {
                        push @{ $week_menu{$todate}{$course}{$meal} ||= [] }, shift(@meal_foods);
                    }
                }
                $init_num++;
            }
        }

        $sth = $DBH->prepare(qq{ INSERT INTO `week_menu` (`ymd`, `course`, `meal`, `menu`) VALUES (?,?,?,?) });
        my $days_cnt = 0;
        foreach my $ymd_p ( keys %week_menu ) {
            foreach my $course_p ( keys $week_menu{$ymd_p} ) {
                foreach my $meal_p ( keys $week_menu{$ymd_p}{$course_p} ) {
                    $sth->execute( $ymd_p, "$course_p", "$meal_p", "$week_menu{$ymd_p}{$course_p}{$meal_p}->[0]" );
                }
            }
            $days_cnt++;
        }
        require "lib/menu_cnt.pl";
    }
    else {
        die $response->status_line;
    }
}
