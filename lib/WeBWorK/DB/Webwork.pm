################################################################################
# WeBWorK mod_perl (c) 1995-2002 WeBWorK Team, Univeristy of Rochester
# $Id$
################################################################################

package WeBWorK::DB::Webwork;

use strict;
use warnings;
use WeBWorK::Set;
use WeBWorK::Problem;

# there should be a `use' line for each database type
use WeBWorK::DB::GDBM;

# new($invocant, $courseEnv)
# $invocant - implicitly set by caller
# $courseEnv - an instance of CourseEnvironment
sub new($$) {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $courseEnv = shift;
	my $dbModule = fullyQualifiedPackageName($courseEnv->{dbInfo}->{wwdb_type});
	my $self = {
		webwork_file => $courseEnv->{dbInfo}->{wwdb_file},
	};
	$self->{webwork_db} = $dbModule->new($self->{webwork_file});
	bless $self, $class;
	return $self;
}

sub fullyQualifiedPackageName($) {
	my $n = shift;
	my $package = __PACKAGE__;
	$package =~ s/([^:]*)$/$n/;
	return $package;
}

# -----

# getSets($userID) - returns a list of sets in the current database for the
#                    specified user
# $userID - the user ID (a.k.a. login name) of the user to get sets for


# -----

# getSet($userID, $setID) - returns a WeBWorK::Set object containing data
#                           from the specified set.
# $userID - the user ID (a.k.a. login name) of the set to retrieve
# $setID - the ID (a.k.a. name) of the set to retrieve

# setSet($set) - if a set with the same ID for the specified user
#                exists, it is replaced. If not, a new set is added.
#                returns true on success, undef on failure.
# $set - a WeBWorK::Set object containing the set data

# deleteSet($userID, $setID) - removes the set with the specified userID and
#                              setID. Returns true on success, undef on failure.
# $userID - the user ID (a.k.a. login name) of the set to delete
# $setID - the ID (a.k.a. name) of the set to delete

# -----

# getSetDefaults($setID) - returns a WeBWorK::Set object containing the default
#                          values for a particular set. (See NOTE)
# setID - id of set to fetch

# setSetDefaults($set) - Replace set defaults with the given set. (See NOTE)
# $set - a WeBWorK::Set object containing set defaults

# deleteSetDefaults($setID) - Remove set defaults with the given ID. (See NOTE)
# $setID - the ID of the set defaults to delete

# -----

# getProblems($userID, $setID) - returns a list of problems in the specified
#                                set for the specified user.
# $userID - the user ID of the user to get problems for
# $setID - the set ID to get problems from

# -----

# getProblem($userID, $setID, $problemNumber) - returns a WeBWorK::Problem
#                                               object containing the problem
#                                               requested
# $userID - the user for which to retrieve the problem
# $setID - the set from which to retrieve the problem
# $problemNumber - the number of the problem to retrieve

# setProblem($problem) - if a problem with the same ID for the specified user
#                        exists, it is replaced. If not, a new problem is added.
#                        returns true on success, undef on failure.
# $problem - a WeBWorK::Problem object containing the object data

# deleteProblem($userID, $setID, $problemNumber) - removes a problem with the
#                                                  specified parameters.
# $userID - the user ID of the problem to delete
# $setID - the ID of the problem's set
# $problemNumber - the problem number of the problem to delete

# -----

# getProblemDefaults($setID, $problemNumber) - Returns a WeBWorK::Problem object
#                                              containing the default values for
#                                              a particular problem. (See NOTE)
# $setID - set id of problem to retrieve
# $problemNumber - problem number of problem to retrieve

# setProblemDefaults($problem) - Replace or add problem defaults with the given
#                                problem. (See NOTE)
# $problem - a WeBWorK::Problem object containing problem defaults

# deleteProblemDefaults($setID, $problemNumber) - remove problem defaults with
#                                                 the given set and problem ID.
#                                                 (See NOTE)
# $setID - the set ID of the problem defaults to delete
# $problemNumber - the problem number of the problem defaults to delete

# -----

# getPSVN($userID, $setID) - look up a PSVN given a user ID and set ID (PSVN
#                            stands for Problem Set Version Number and
#                            uniquely identifies a user's version of a set.)
# $userID - the user ID to lookup
# $serID - the set ID to lookup

# -----

# decode($string) - decodes a quasi-URL-encoded hash from a hash-based
#                   webwork database. unescapes \& and \= in VALUES ONLY.
# $string - string to decode
sub decode($) {
	my $string = shift;
	my %hash = $string =~ /(.*?)(?<!\\)=(.*?)(?:(?<!\\)&|$)/g;
	$hash{$_} =~ s/\\(.)/$1/ foreach (keys %hash); # unescape anything
	return %hash;
}

# encode(%hash) - encodes a hash as a quasi-URL-encoded string for insertion
#                 into a hash-based webwork database. Escapes & and = in
#                 VALUES ONLY.
# %hash - hash to encode
sub encode(%) {
	my %hash = @_;
	my $string;
	foreach (keys %hash) {
		$hash{$_} =~ s/(=|&)/\\$1/; # escape & and =
		$string .= "$_=$hash{$_}&";
	}
	chop $string; # remove final '&' from string for old code :p
	return $string;
}

# -----

# hash2set(%hash) - places selected fields from a webwork database record
#                   in a WeBWorK::Set object, which is then returned.
# %hash - a hash representing a database record
sub hash2set(%) {
	my %hash = @_;
	my $set = WeBWorK::Set->new;
	$set->id             ( $hash{stnm} ) if defined $hash{stnm};
	$set->login_id       ( $hash{stlg} ) if defined $hash{stlg};
	$set->set_header     ( $hash{shfn} ) if defined $hash{shfn};
	$set->problem_header ( $hash{phfn} ) if defined $hash{phfn};
	$set->open_date      ( $hash{opdt} ) if defined $hash{opdt};
	$set->due_date       ( $hash{dudt} ) if defined $hash{dudt};
	$set->answer_date    ( $hash{andt} ) if defined $hash{andt};
	return $set;
}

# set2hash($set) - unpacks a WeBWorK::Set object and returns PART of a hash
#                  suitable for storage in the webwork database.
# $set - a WeBWorK::Set object.
sub set2hash($) {
	my $set = shift;
	my %hash;
	$hash{stnm} = $set->id             if defined $set->id;
	$hash{stlg} = $set->login_id       if defined $set->login_id;
	$hash{shfn} = $set->set_header     if defined $set->set_header;
	$hash{phfn} = $set->problem_header if defined $set->problem_header;
	$hash{opdt} = $set->open_date      if defined $set->open_date;
	$hash{dudt} = $set->due_date       if defined $set->due_date;
	$hash{andt} = $set->answer_date    if defined $set->answer_date;
}

# hash@problem($n, %hash) - places selected fields from a webwork
#                                       database record in a WeBWorK::Problem
#                                       object, which is then returned.
# $n - the problem number to extract
# %hash - a hash representing a database record
sub hash2problem($%) {
	my $n = shift;
	my %hash = @_;
	my $problem = WeBWorK::Problem->new(id => $n);
	$problem->set_id        ( $hash{stnm}    ) if defined $hash{stnm};
	$problem->source_file   ( $hash{"pfn$n"} ) if defined $hash{"pfn$n"};
	$problem->value         ( $hash{"pva$n"} ) if defined $hash{"pva$n"};
	$problem->max_attempts  ( $hash{"pmia$n"}) if defined $hash{"pmia$n"};
	$problem->problem_seed  ( $hash{"pse$n"} ) if defined $hash{"pse$n"};
	$problem->status        ( $hash{"pst$n"} ) if defined $hash{"pst$n"};
	$problem->attempted     ( $hash{"pat$n"} ) if defined $hash{"pat$n"};
	$problem->last_answer   ( $hash{"pan$n"} ) if defined $hash{"pan$n"};
	$problem->num_correct   ( $hash{"pca$n"} ) if defined $hash{"pca$n"};
	$problem->num_incorrect ( $hash{"pia$n"} ) if defined $hash{"pia$n"};
	
}

# problem2hash($problem) - unpacks a WeBWorK::Problem object and returns PART
#                          of a hash suitable for storage in the webwork
#                          database.
# $problem - a WeBWorK::Problem object
sub problem2hash($) {
	my $problem = shift;
	my $n = $problem->id;
	$hash{stnm}    = $problem->set_id        if defined $problem->set_id;
	$hash{"pfn$n"} = $problem->source_file   if defined $problem->source_file;
	$hash{"pva$n"} = $problem->value         if defined $problem->value;
	$hash{"pmia$n"}= $problem->max_attempts  if defined $problem->max_attempts;
	$hash{"pse$n"} = $problem->problem_seed  if defined $problem->problem_seed;
	$hash{"pst$n"} = $problem->status        if defined $problem->status;
	$hash{"pat$n"} = $problem->attempted     if defined $problem->attempted;
	$hash{"pan$n"} = $problem->last_answer   if defined $problem->last_answer;
	$hash{"pca$n"} = $problem->num_correct   if defined $problem->num_correct;
	$hash{"pia$n"} = $problem->num_incorrect if defined $problem->num_incorrect;
	return %hash;
}

1;
