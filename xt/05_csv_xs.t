use strict;
use warnings;
use utf8;
use Test::More;
use Win32::Unicode;
use File::Temp qw/tempdir tempfile/;

eval {
    require Text::CSV_XS;
};
plan skip_all => "Text::CSV_XS is not installed." if $@;

subtest getline => sub {
    my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
    binmode $fh, ":utf8";
    print $fh <<'CSV';
one,two,three
one,"two",three
one,"tw
o",three
CSV
    close $fh;

    my $file = Win32::Unicode::File->new(r => $filename) or die $!;
    my $csv = Text::CSV_XS->new({ binary => 1 });
    my @rows;
    while (my $row = $csv->getline($file)) {
        push @rows, $row;
    }
    ok($csv->eof) or $csv->error_diag();
    is( @rows, 3 );
    is_deeply( \@rows, [
        [ "one", "two", "three" ],
        [ "one", "two", "three" ],
        [ "one", "tw\no", "three" ],
    ]);

    done_testing;
};

done_testing;
