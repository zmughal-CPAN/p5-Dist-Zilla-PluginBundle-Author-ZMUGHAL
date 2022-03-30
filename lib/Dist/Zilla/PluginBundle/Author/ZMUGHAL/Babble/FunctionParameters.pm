package Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters;

use strict;
use warnings;
use Import::Into;
use Mu;

ro setup_package => (
  default => sub { 'Orbital::Transfer::Common::Setup' },
);

lazy _import_info => sub {
  my ($self) = @_;
  $self->setup_package->import::into(0);
  my $fp_config = $^H{'Function::Parameters/config'};
  $self->setup_package->unimport::out_of(0);
  return +{
    'fp' => $fp_config,
  };
};

lazy _fp_keywords_re => sub {
  my ($self) = @_;
  return
    '(?:'
    . join("|", map quotemeta, keys %{ $self->_import_info->{fp} })
    . ')';
};

my $FPTypeRE = q{
  (?:
    [^$@%]+ | \( (?&PerlScalarExpression) \)
  )
};
my $FPParamRE = q{
    (?:
      (?> (?&PerlBabbleFPType)? )       # TYPE
      (?> (?&PerlOWS) )
      (?> :? )                          # NAMED
      (?> \$ (?&PerlIdentifier) )       # VAR
      (?>
        (?&PerlOWS)
        (?: = )                         # HASDEFAULT
        (?&PerlOWS)
        (?: (?&PerlScalarExpression)? ) # DEFAULT
      )?
    )
  |
  (?:
    (?: (?> [$@%] ) (?> (?&PerlIdentifier)? ) ) # VAR
  )
};

my $FPParamListPartial = q{
  (?&PerlBabbleFPParam)
  (?: (?&PerlOWS) [,] (?&PerlOWS) (?&PerlBabbleFPParam))*?
};

my $FPParamListComplete = qq{
 \\(
   (?> (?&PerlOWS) )
   (?:
     (?:
       $FPParamListPartial
       [:]
     )?
     (?:
       $FPParamListPartial
     )
   )??
   (?> (?&PerlOWS) )
 \\)
};

sub extend_grammar {
  my ($self, $g) = @_;
  $g->add_rule(BabbleFPType => $FPTypeRE );
  $g->add_rule(BabbleFPParam => $FPParamRE );
  $g->add_rule(BabbleFPParamList => $FPParamListComplete );
  $g->add_rule(FPDeclaration => qq{
    @{[ $self->_fp_keywords_re ]}
    (?&PerlOWS)
    (?: (?&PerlIdentifier)(?&PerlOWS) )?+
    (?> (?&PerlBabbleFPParamList) )
    (?&PerlOWS)
    (?&PerlBlock)
  });
  $g->augment_rule(SubroutineDeclaration => '(?&PerlFPDeclaration)');
  $g->augment_rule(AnonymousSubroutine => '(?&PerlFPDeclaration)');
}

sub transform_to_plain {
  my ($self, $top) = @_;
  $top->remove_use_statement('Function::Parameters');
  $top->each_match_within(FPDeclaration => [
      [ kw => $self->_fp_keywords_re ],
      [ name => '(?&PerlOWS) (?:(?&PerlIdentifier)(?&PerlOWS))?+' ],
      [ sig => '(?&PerlBabbleFPParamList)' ],
      [ rest => '(?&PerlOWS) (?&PerlBlock)' ],
    ] => sub {
      my ($m) = @_;
      my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
      my $kw_text = $kw->text;
      my $kw_info = $self->_import_info->{fp}{$kw_text};
      $kw->replace_text('sub');
      my $sig_text = $sig->text;
      #use DDP; p $self->_fp_arg_code_deparse( $kw_text, $sig_text );
      my $front = ('my $self = shift;')x!!$kw_info->{shift}
                  .($sig_text && $sig_text ne '()' ? "my ${sig_text} = \@_;": '');
      $rest->transform_text(sub { s/^(\s*)\{/${1}{ ${front}/ });
      $sig->replace_text('');
  });
}

sub _fp_arg_code_deparse {
  my ($self, $kw_text, $sig_text) = @_;
  my $text = $self->_deparse_fp( $kw_text, $sig_text );
  (my $replaced = $text) =~ s/\Qpackage Eval::Closure::Sandbox_\E.*?^\s*}$//ms;
  $replaced =~ s/\A[^{]*?\{\s*|42;\n\}\Z//msg;
  $replaced =~ s/^\s*|\s*$//msg;
  $replaced =~ s/\n+/ /msg;

  $replaced;
}

sub _deparse_fp {
  require B::Deparse;
  require Eval::Closure;
  # https://github.com/mauke/Function-Parameters/issues/29
  my $deparse = B::Deparse->new("-d");
  my ($self, $kw_text, $sig_text) = @_;
  my $code = qq{
    use @{[ $self->setup_package ]};
    $kw_text $sig_text { 42 };
  };
  my $coderef = Eval::Closure::eval_closure(
    source => $code,
  );
  my $text = $deparse->coderef2text( $coderef );
}

1;
