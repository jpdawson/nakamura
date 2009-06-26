#!/usr/bin/perl

#{{{Documentation
=head1 SYNOPSIS

site perl script. Provides a means of manipulating sites in a sytem from the
command line. Additionally serves as a reference example for using the
Sling::Site library.

=head1 OPTIONS

Usage: perl site.pl [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --additions or -A (file)    - File containing list of sites to add.
 --add or -a (actOnSite)     - add site.
 --alter or -c (actOnSite)   - alter (update) site.
 --auth (type)               - Specify auth type. If ommitted, default is used.
 --delete or -d (actOnSite)  - delete site.
 --exists or -e (actOnSite)  - check whether site exists.
 --help or -?                - view the script synopsis and options.
 --joinable or -j (joinable) - Joinable status of site (yes|no|withauth).
 --log or -L (log)           - Log script output to specified log file.
 --man or -M                 - view the full script documentation.
 --pass or -p (password)     - Password of user performing actions.
 --property or -P (property) - Specify property to set on site.
 --template or -T (template) - Template location to use for site.
 --threads or -t (threads)   - Used with -F, defines number of parallel
                               processes to have running through file.
 --url or -U (URL)           - URL for system being tested against.
 --user or -u (username)     - Name of user to perform any actions as.
 --verbose or -v             - Increase verbosity of output.
 --view or -V (actOnSite)    - view site.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl site.pl --man

=head1 Example Usage

=over

=item Authenticate and add a site with id testsite:

 perl site.pl -U http://localhost:8080 --add testsite --user admin --pass admin

=item Authenticate and check whether site with id testsite exists:

 perl site.pl -U http://localhost:8080 --exists testsite --user admin --pass admin

=item Authenticate and alter site testsite to set its joinable property to yes:

 perl site.pl -U http://localhost:8080 --alter testsite --joinable yes --user admin --pass admin

=item Authenticate and view site testsite details:

 perl site.pl -U http://localhost:8080 --view testsite --user admin --pass admin

=item Authenticate and delete site testsite with verbose output enabled:

 perl site.pl -U http://localhost:8080 --delete testsite --user admin --pass admin --verbose

=item Authenticate and add site testsite with property p1=v1 and property p2=v2:

 perl site.pl -U http://localhost:8080 --add testsite2 --property p1=v1 --property p2=v2 --user admin --pass admin

=item Authenticate and add site testsite with template /sitetemplate.html:

 perl site.pl -U http://localhost:8080 --add testsite --template /sitetemplate.html --user admin --pass admin

=back

=cut
#}}}

#{{{imports
use strict;
use lib qw ( .. );
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Sling::Site;
use Sling::UserAgent;
use Sling::URL;
#}}}

#{{{options parsing
my $addSite;
my $additions;
my $alterSite;
my $auth;
my $deleteSite;
my $existsSite;
my $help;
my $joinable;
my $log;
my $man;
my $numberForks = 1;
my $password;
my @properties;
my $template;
my $url = "http://localhost";
my $username;
my $verbose;
my $viewSite;

GetOptions (
    "add|a=s" => \$addSite,
    "addition|A=s" => \$additions,
    "alter|A=s" => \$alterSite, 
    "auth=s" => \$auth,
    "delete|d=s" => \$deleteSite,
    "exists|e=s" => \$existsSite,
    "help|?" => \$help,
    "joinable|j=s" => \$joinable,
    "log|L=s" => \$log,
    "man|M" => \$man,
    "pass|p=s" => \$password,
    "property|P=s" => \@properties,
    "template|T=s" => \$template,
    "threads|t=i" => \$numberForks,
    "url|U=s" => \$url,
    "user|u=s" => \$username,
    "verbose|v+" => \$verbose,
    "view|V=s" => \$viewSite
) or pod2usage(-exitstatus => 2, -verbose => 1);

pod2usage(-exitstatus => 0, -verbose => 1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

$numberForks = ( $numberForks || 1 );
$numberForks = ( $numberForks =~ /^[0-9]+$/ ? $numberForks : 1 );
$numberForks = ( $numberForks < 32 ? $numberForks : 1 );

$url =~ s/(.*)\/$/$1/;
$url = ( $url !~ /^http/ ? "http://$url" : "$url" );

my %joinableOptions = ( 'yes', 1, 'no', 1, 'withauth', 1 );
if ( defined $joinable ) {
    if ( ! $joinableOptions{ $joinable } ) {
        die "Joinable option must be one of yes, no, or withauth!";
    }
}

$addSite = Sling::URL::strip_leading_slash( $addSite );
$alterSite = Sling::URL::strip_leading_slash( $alterSite );
$deleteSite = Sling::URL::strip_leading_slash( $deleteSite );
$existsSite = Sling::URL::strip_leading_slash( $existsSite );
$viewSite = Sling::URL::strip_leading_slash( $viewSite );
$template = Sling::URL::add_leading_slash( $template );
#}}}

#{{{ main execution path
if ( defined $additions ) {
    my $message = "Running through all site actions in file \"$additions\":\n";
    Sling::Print::print_with_lock( "$message", $log );
    my @childs = ();
    for ( my $i = 0 ; $i < $numberForks ; $i++ ) {
	my $pid = fork();
	if ( $pid ) { push( @childs, $pid ); } # parent
	elsif ( $pid == 0 ) { # child
            my $lwpUserAgent = Sling::UserAgent::get_user_agent( $log, $url, $username, $password, $auth );
            my $site = new Sling::Site( $url, $lwpUserAgent, $verbose );
	    my $path;
            $site->update_from_file( $additions, $i, $numberForks, $log );
	    exit( 0 );
	}
	else {
            die "Could not fork $i!";
	}
    }
    foreach ( @childs ) { waitpid( $_, 0 ); }
}
else {
    my $lwpUserAgent = Sling::UserAgent::get_user_agent( $log, $url, $username, $password, $auth );
    my $site = new Sling::Site( $url, $lwpUserAgent, $verbose );
    if ( defined $addSite ) {
        $site->update( $addSite, $template, $joinable, \@properties, $log );
    }
    elsif ( defined $alterSite ) {
        $site->update( $alterSite, $template, $joinable, \@properties, $log );
    }
    elsif ( defined $deleteSite ) {
        $site->delete( $deleteSite, $log );
    }
    elsif ( defined $existsSite ) {
        $site->exists( $existsSite, $log );
    }
    elsif ( defined $viewSite ) {
        $site->view( $viewSite, $log );
    }
    Sling::Print::print_result( $site, $log );
}
#}}}

1;
