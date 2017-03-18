use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::ZMUGHAL;
# ABSTRACT: A plugin bundle for distributions built by ZMUGHAL

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

sub configure {
	my $self = shift;

	$self->add_bundle('Author::ZMUGHAL::Basic');
}

__PACKAGE__->meta->make_immutable;
1;
