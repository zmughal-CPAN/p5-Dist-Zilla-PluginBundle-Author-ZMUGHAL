use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::ZMUGHAL::Basic;
# ABSTRACT: A plugin bundle that sets up a basic set of plugins for ZMUGHAL

use Moose;
with qw(
	Dist::Zilla::Role::PluginBundle::Easy
	Dist::Zilla::Role::PluginBundle::Config::Slicer ),
	'Dist::Zilla::Role::PluginBundle::PluginRemover' => { -version => '0.103' },
;

sub configure {
	my $self = shift;

	$self->add_bundle('Filter', {
		'-bundle' => '@Basic',
		'-remove' => [ 'ExtraTests' ],
	});

	$self->add_plugins(
		qw(
			MetaJSON
			AutoPrereqs
			PkgVersion
			CheckChangeLog
			GithubMeta
			PodWeaver
			MinimumPerl
		)
	);

	$self->add_plugins(
		['ReadmeAnyFromPod' => [
			#; generate README.pod in root (so that it can be displayed on GitHub)
			type => 'pod',
			filename => 'README.pod',
			location => 'root',
		]],

		['Git::CommitBuild' => [
			#; no build commits
			branch => '',
			#; release commits
			release_branch  => 'build/%b',
			release_message => 'Release build of v%v (on %b)',
		]],
	);

	$self->add_bundle(
		'Git' => {
			allow_dirty => [
					'dist.ini',
					'README'
				],
			push_to => [
					'origin',
					'origin build/master:build/master'
				] ,
		}
	);
}

__PACKAGE__->meta->make_immutable;
1;
