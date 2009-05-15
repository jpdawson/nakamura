#!/usr/bin/perl

package Sling::GroupUtil;

=head1 NAME

GroupUtil - Utility library returning strings representing Rest queries that
perform group related actions in the system.

=head1 ABSTRACT

GroupUtil perl library essentially provides the request strings needed to
interact with group functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut

#{{{imports
use strict;
use lib qw ( .. );
use Sling::Util;
#}}}

#{{{sub add_setup

=pod

=head2 add_setup

Returns a textual representation of the request needed to add the group to the
system.

=cut

sub add_setup {
    my ( $baseURL, $actOnGroup, $actOnPass, $actOnEmail, $actOnFirst, $actOnLast ) = @_;
    die "No base url defined to add against!" unless defined $baseURL;
    die "No group name defined to add!" unless defined $actOnGroup;
    $actOnGroup = Sling::Util::urlencode( $actOnGroup );
    my $postVariables = "\$postVariables = [':name','$actOnGroup']";
    return "post $baseURL/system/userManager/group.create.html $postVariables";
}
#}}}

#{{{sub add_eval

=pod

=head2 add_eval

Check result of adding group to the system.

=cut

sub add_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to delete the group from
the system.

=cut

sub delete_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    die "No base url defined to delete against!" unless defined $baseURL;
    die "No group name defined to delete!" unless defined $actOnGroup;
    $actOnGroup = Sling::Util::urlencode( $actOnGroup );
    my $postVariables = "\$postVariables = []";
    return "post $baseURL/system/userManager/group/$actOnGroup.delete.html?sling:authRequestLogin=1 $postVariables";
}
#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Check result of deleting group from the system.

=cut

sub delete_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

#{{{sub exists_setup

=pod

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
group exists in the system.

=cut

sub exists_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    die "No base url to check existence against!" unless defined $actOnGroup;
    die "No group to check existence of defined!" unless defined $actOnGroup;
    $actOnGroup = Sling::Util::urlencode( $actOnGroup );
    return "get $baseURL/system/userManager/group/$actOnGroup.json";
}
#}}}

#{{{sub exists_eval

=pod

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the group does exist in the system, else
false.

=cut

sub exists_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

#{{{sub view_setup

=pod

=head2 view_setup

Returns a textual representation of the request needed to view a given group in
the system. This function is similar to exists expect authentication is forced.

=cut

sub view_setup {
    my ( $baseURL, $actOnGroup ) = @_;
    die "No base url to check existence against!" unless defined $actOnGroup;
    die "No group to check existence of defined!" unless defined $actOnGroup;
    $actOnGroup = Sling::Util::urlencode( $actOnGroup );
    return "get $baseURL/system/userManager/group/$actOnGroup.json?sling:authRequestLogin=1";
}
#}}}

#{{{sub view_eval

=pod

=head2 view_eval

Inspects the result returned from issuing the request generated in view_setup
returning true if the result indicates the group view was returned, else false.

=cut

sub view_eval {
    my ( $res ) = @_;
    return ( $$res->code =~ /^200$/ );
}
#}}}

1;
