package Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer;
# ABSTRACT: A plugin bundle for Orbital Transfer

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

use Dist::Zilla::Plugin::Babble ();
use Babble 0.090009 ();
use Dist::Zilla::Plugin::RunExtraTests ();
use Dist::Zilla::Plugin::Test::MinimumVersion ();
use Dist::Zilla::Plugin::Test::Perl::Critic ();
use Dist::Zilla::Plugin::Test::PodSpelling ();
use Dist::Zilla::Plugin::PodCoverageTests ();

use constant FP_OT => 'Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters::OT';
use Subclass::Of 'Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters',
	-package => FP_OT,
	-has     => [
		setup_package => sub { 'Orbital::Transfer::Common::Setup' },
	];



sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Author::ZMUGHAL::Basic',
	});

	$self->add_plugins(
		['Babble' => {
			plugin => [
				FP_OT,
			qw(
				::DefinedOr
				::SubstituteAndReturn
				::State
				::Ellipsis
			) ],
		}],
	);

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
