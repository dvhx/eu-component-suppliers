#!/usr/bin/env perl
use strict;
use warnings;

my $csv_file    = 'suppliers.csv';
my $readme_file = 'README.md';
my $start       = '<!-- SUPPLIERS_TABLE:START -->';
my $end         = '<!-- SUPPLIERS_TABLE:END -->';

open(my $csv_fh, '<:encoding(UTF-8)', $csv_file) or die "Can't open $csv_file: $!";
my @lines = <$csv_fh>;
close $csv_fh;
shift @lines; # drop header row

my @rows;
for my $line (@lines) {
    chomp $line;
    next unless length $line;

    # Split on commas that are outside double quotes.
    my @f = split /,(?=(?:[^"]*"[^"]*")*[^"]*$)/, $line;
    s/^"|"$//g for @f;
    my ($url, $ship, $free, $ships_to) = @f;

    (my $label = $url) =~ s{^https?://}{};
    $label =~ s{/$}{};

    $ship = "\x{20ac}$ship" unless $ship eq '-';
    $free = "\x{20ac}$free" unless $free eq '-';

    $ships_to = $ships_to eq 'world' ? 'Worldwide'
              : $ships_to eq 'eu'    ? 'All EU'
              : join(', ', map { uc } split /,/, $ships_to);

    push @rows, "| [$label]($url) | $ship | $free | $ships_to |";
}

my $table = join("\n",
    $start,
    '| Supplier | Shipping Cost | Free Shipping Threshold | Ships To |',
    '|---|---|---|---|',
    @rows,
    $end,
);

open(my $r_fh, '<:encoding(UTF-8)', $readme_file) or die "Can't open $readme_file: $!";
local $/;
my $content = <$r_fh>;
close $r_fh;

if ($content =~ /\Q$start\E.*?\Q$end\E/s) {
    $content =~ s/\Q$start\E.*?\Q$end\E/$table/s;
} else {
    $content =~ s/(\Q[suppliers.csv](suppliers.csv)\E\n)/$1\n$table\n/;
}

open(my $out_fh, '>:encoding(UTF-8)', $readme_file) or die "Can't write $readme_file: $!";
print $out_fh $content;
close $out_fh;

print "Updated $readme_file with " . scalar(@rows) . " suppliers.\n";
