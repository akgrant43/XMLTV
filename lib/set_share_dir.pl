# Fragment of Perl code included from some .PL files.  Read $in,
# change lines defining '$SHARE_DIR' and write to the file given
# on the command line.
#
use IO::File;
use strict;
my $out = shift @ARGV; die "no output file given" if not defined $out;
my $share_dir = shift @ARGV;
die "no final share/ location given" if not defined $share_dir;
my $out_fh = new IO::File "> $out" or die "cannot write to $out: $!";
my $in_fh = new IO::File "< $in" or die "cannot read $in: $!";
my $seen = 0;
while (<$in_fh>) {
    s/^my \$SHARE_DIR =.*/my \$SHARE_DIR='$share_dir'; \# by $0/ && $seen++;
    print $out_fh $_;
}
if ($seen == 0) {
    die "did not see SHARE_DIR line in $in";
}
elsif ($seen == 1) {
    # Okay.
}
elsif ($seen >= 2) {
    warn "more than one SHARE_DIR line in $in";
}
else { die }
close $out_fh or die "cannot close $out: $!";
close $in_fh or die "cannot close $in: $!";

