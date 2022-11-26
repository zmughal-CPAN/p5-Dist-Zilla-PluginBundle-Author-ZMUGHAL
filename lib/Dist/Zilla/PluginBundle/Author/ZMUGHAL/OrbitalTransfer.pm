package Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer;
# ABSTRACT: A plugin bundle for Orbital Transfer

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

use Dist::Zilla::Plugin::RunExtraTests ();
use Dist::Zilla::Plugin::Test::MinimumVersion ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling ();
use Dist::Zilla::Plugin::PodCoverageTests ();

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Author::ZMUGHAL::Basic',
	});

	# ; run the xt/ tests
	$self->add_plugins( qw( RunExtraTests) );

	# ; code must target at least 5.8.0
	$self->add_plugins(
		['Test::MinimumVersion' => {
			max_target_perl => '5.8.0'
		}],
	);

	$self->add_plugins(qw(
		Test::Perl::Critic
		Test::PodSpelling
		PodCoverageTests
	));
}

__PACKAGE__->meta->make_immutable;
1;
