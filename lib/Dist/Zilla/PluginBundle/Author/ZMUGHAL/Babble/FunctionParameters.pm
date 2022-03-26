package Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters;

use strict;
use warnings;
use Import::Into;
use Moo;

has setup_package => (
  is => 'ro',
  default => sub { 'Orbital::Transfer::Common::Setup' },
);

has _import_info => (
  is => 'lazy',
);

sub _build__import_info {
  my ($self) = @_;
  $self->setup_package->import::into(0);
  my $fp_config = $^H{'Function::Parameters/config'};
  $self->setup_package->unimport::out_of(0);
  return +{
    'fp' => $fp_config,
  };
}

has _fp_keywords_re => (
  is => 'lazy',
);

sub _build__fp_keywords_re {
  my ($self) = @_;
  return
    '(?:'
    . join("|", map quotemeta, keys %{ $self->_import_info->{fp} })
    . ')';
}

sub extend_grammar {
  my ($self, $g) = @_;
  $g->add_rule(MethodDeclaration =>
    $self->_fp_keywords_re
    .'(?&PerlOWS)(?:(?&PerlIdentifier)(?&PerlOWS))?+'
    .'(?:(?&PerlList))?+' # was PerlParenthesesList
    .'(?&PerlOWS) (?&PerlBlock)'
  );
  $g->augment_rule(SubroutineDeclaration => '(?&PerlMethodDeclaration)');
  $g->augment_rule(AnonymousSubroutine => '(?&PerlMethodDeclaration)');
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_statement('Function::Parameters');
  $top->remove_use_statement('Method::Signatures::PP');
  $top->remove_use_statement('Method::Signatures::Simple');
  $top->each_match_within(MethodDeclaration => [
      [ kw => $self->_fp_keywords_re ],
      [ name => '(?&PerlOWS)(?:(?&PerlIdentifier)(?&PerlOWS))?+' ],
      [ sig => '(?:(?&PerlList))?+' ],
      [ rest => '(?&PerlOWS) (?&PerlBlock)' ],
    ] => sub {
      my ($m) = @_;
      my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
      my $kw_orig = $kw->text;
      my $kw_info = $self->_import_info->{fp}{$kw_orig};
      $kw->replace_text('sub');
      my $sig_text = $sig->text;
      my $front = ('my $self = shift;')x!!$kw_info->{shift}
                  .($sig_text && $sig_text ne '()' ? "my ${sig_text} = \@_;": '');
      $rest->transform_text(sub { s/^(\s*)\{/${1}{ ${front}/ });
      unless (($m->subtexts('name'))[0]) {
        #$rest->transform_text(sub { s/$/;/ });
      }
      $sig->replace_text('');
  });
}

1;
