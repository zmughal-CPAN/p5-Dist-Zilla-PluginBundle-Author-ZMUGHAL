package Dist::Zilla::PluginBundle::Author::ZMUGHAL::OrbitalTransfer;
# ABSTRACT: A plugin bundle for Orbital Transfer

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Author::ZMUGHAL::Basic',
		'-remove' => [ 'PodWeaver' ],
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
