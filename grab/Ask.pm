# A few routines for asking the user questions in --configure.

package XMLTV::Ask;
use strict;
use base 'Exporter';
use vars '@EXPORT';
use Log::TraceMessages qw(t d);
use Carp qw(croak);
@EXPORT = qw(ask askQuestion askBooleanQuestion askManyBooleanQuestions);

sub ask( $ );
sub askQuestion( $$@ );
sub askBooleanQuestion( $$ );

sub ask( $ )
{
    print "$_[0]";
    my $result=<>;
    chop($result) if ( defined($result) );
    return($result);
}

# Ask a question where the answer is one of a set of alternatives.
#
# Parameters:
#   question text
#   default choice
#   Remaining arguments are the choices available.
#
sub askQuestion( $$@ )
{
    my $question=shift(@_); die if not defined $question;
    my $default=shift(@_); die if not defined $default;
    my @options=@_; die if not @options;
    t "asking question $question, default $default";
    croak "default $default not in options"
      if not grep { $_ eq $default } @options;

    my $options_size = length("@options");
    t "size of options: $options_size";
    my $all_digits = not ((my $tmp = join('', @options)) =~ tr/0-9//c);
    t "all digits? $all_digits";
    if ($options_size < 20 or $all_digits) {
	# Simple style, one line question.
	my $str = "$question [".join(',',@options)." (default=$default)] ";
	while ( 1 ) {
	    my $res=ask($str);
	    if ( !defined($res) || $res eq "" ) {
		return($default);
	    }

	    # Check for exact match, then for substring matching.
	    foreach (@options) {
		return $_ if $_ eq $res;
	    }
	    my @poss;
	    foreach (@options) {
		push @poss, $_ if /\Q$res\E/i;
	    }
	    if ( @poss == 1 ) {
		# Unambiguous substring match.
		return $poss[0];
	    }

	    print "invalid response, please choose one of ".join(',', @options)."\n\n";
	}
    }
    else {
	# Long list of options, present as numbered multiple choice.
	print "$question\n";
	my $optnum = 0;
	my (%num_to_choice, %choice_to_num);
	foreach (@options) {
	    print "$optnum: $_\n";
	    $num_to_choice{$optnum} = $_;
	    $choice_to_num{$_} = $optnum;
	    ++ $optnum;
	}
	$optnum--;
	my $r=undef;
	my $default_num = $choice_to_num{$default};
	die if not defined $default_num;
	while (!defined($r) ) {
	    $r = askQuestion('Select one:',
			     $default_num, 0 .. $optnum);
	    if ( defined($r) && defined($num_to_choice{$r}) ) {
		return $num_to_choice{$r};
	    }
	    print "invalid response, please choose one of "
	      .0 .. $optnum."\n\n";
	    $r=undef;
	}
    }
}

# Ask a yes/no question.
#
# Parameters: question text,
#             default (true or false)
#
# Returns true or false.
#
sub askBooleanQuestion( $$ )
{
    my ($text, $default) = @_;
    my $r = askQuestion($text, ($default ? 'yes' : 'no'), 'yes', 'no');
    if ($r eq 'yes') {
	return 1;
    }
    elsif ($r eq 'no') {
	return 0;
    }
    else { die }
}

# Ask yes/no questions with option 'default to all'.
#
# Parameters: default (true or false),
#             question texts (one per question).
#
# Returns: lots of booleans, one for each question.
#
sub askManyBooleanQuestions( $@ )
{
    my $default = shift;
    my @r;
    while (@_) {
	my $q = shift @_;
	my $r = askQuestion($q, ($default ? 'yes' : 'no'),
			    'yes', 'no', ($default ? 'all' : 'none'));
	if ($r eq 'yes') {
	    push @r, 1;
	} elsif ($r eq 'no') {
	    push @r, 0;
	} elsif ($r eq 'all' or $r eq 'none') {
	    my $bool = ($r eq 'all');
	    push @r, $bool;
	    foreach (@_) {
		print "$_ ", ($bool ? 'yes' : 'no'), "\n";
		push @r, $bool;
	    }
	    last;
	} else { die }
    }
    return @r;
}

1;
