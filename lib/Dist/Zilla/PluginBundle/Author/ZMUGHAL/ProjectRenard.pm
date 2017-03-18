package Dist::Zilla::PluginBundle::Author::ZMUGHAL::ProjectRenard;
# ABSTRACT: A plugin bundle for Project Renard

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

# Dependencies
use Test::Perl::Critic ();
use Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign ();
use App::scan_prereqs_cpanfile ();
use Pod::Coverage ();
use Pod::Weaver::Section::Extends ();
use Pod::Weaver::Section::Consumes ();
use Pod::Elemental::Transformer::List ();

sub configure {
	my $self = shift;

	# ; run the xt/ tests
	$self->add_plugins( qw( RunExtraTests) );

	$self->add_plugins(qw(
		Test::Perl::Critic
		Test::PodSpelling
		PodCoverageTests
	));
}

__PACKAGE__->meta->make_immutable;
1;
