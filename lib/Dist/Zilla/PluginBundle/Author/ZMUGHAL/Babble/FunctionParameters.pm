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
      #(?<type>
        (?> (?&PerlBabbleFPType)? )
      #)
      (?> (?&PerlOWS) )
      #(?<named>
        (?> :? )
      #)
      #(?<var>
        (?> \$ (?&PerlIdentifier) )
      #)
      (?>
        (?&PerlOWS)
        #(?<hasdefault>
          (?: = )
        #)
        (?&PerlOWS)
        #(?<default>
          (?: (?&PerlScalarExpression)? )
        #)
      )?
    )
  |
  (?:
    #(?<other>
      (?: (?> [$@%] ) (?> (?&PerlIdentifier)? ) )
    #)
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
       (?&PerlOWS) [:] (?&PerlOWS)
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

sub _do_transform {
  my ($self, $top, $cb) = @_;
  $top->remove_use_statement('Function::Parameters');
  $top->each_match_within(FPDeclaration => [
      [ kw => $self->_fp_keywords_re ],
      [ name => '(?&PerlOWS) (?:(?&PerlIdentifier)(?&PerlOWS))?+' ],
      [ sig => '(?&PerlBabbleFPParamList)' ],
      [ rest => '(?&PerlOWS) (?&PerlBlock)' ],
    ] => sub {
      my ($m) = @_;
      my $gr = $m->grammar_regexp;
      my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
      my $kw_text = $kw->text;
      my $kw_info = $self->_import_info->{fp}{$kw_text};
      my $sig_text = $sig->text;

      (my $inner_sig = $sig_text) =~ s/(?: \A \( (?&PerlOWS) |  (?&PerlOWS) \) \Z ) $gr//xg;
      my ($invocant_pl, $rest_pl) = $inner_sig =~ /
        \A
        (?:
        ($FPParamListPartial)
        (?&PerlOWS) [:] (?&PerlOWS)
        )?
        ($FPParamListPartial)
        \Z $gr/x;

      my @invocants = $self->_parse_param_list($m, $invocant_pl);
      my @params = $self->_parse_param_list($m, $rest_pl);

      $cb->($m, $kw_text, \@invocants, \@params);
  });

}

sub transform_to_plain {
  my ($self, $top) = @_;
  $self->_do_transform($top, sub {
    my ($m, $kw_text, $invocants, $params) = @_;

    my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
    my $kw_info = $self->_import_info->{fp}{$kw_text};
    $kw->replace_text('sub');

    my @invocant_vars;
    my @params_vars;
    if( ! @$invocants && $kw_info->{shift} ) {
      push @invocant_vars, split ' ', $kw_info->{shift};
    } elsif( @$invocants ) {
      push @invocant_vars, map { $_->{var} } @$invocants;
    }
    push @params_vars, map { $_->{var} } @$params;

    my @front_statements;
    if( @invocant_vars ) {
      my $shift_perl = join "; ", map { "my $_ = shift" } @invocant_vars;
      push @front_statements, $shift_perl;
    }
    if( @params_vars ) {
      my $params_perl = join ", ", @params_vars;
      push @front_statements, "my ($params_perl) = \@_";
    }
    my $front = join "; ", @front_statements;
    $front .= ";";
    $self->_transform_place_front_in_block($rest, $front);
    $sig->replace_text('');
  });
}

sub transform_to_plain_via_deparse {
  my ($self, $top) = @_;
  $self->_do_transform($top, sub {
    my ($m, $kw_text, $invocants, $params) = @_;

    my ($kw, $sig, $rest) = @{$m->submatches}{qw(kw sig rest)};
    my $kw_info = $self->_import_info->{fp}{$kw_text};
    $kw->replace_text('sub');

    my $sig_text = '';
    $sig_text .= '(';

    if( @$invocants ) {
      $sig_text .= join ", ", map {
        $_->{var}
      } @$invocants;
      $sig_text .= " : ";
    }
    if( @$params ) {
      $sig_text .= join ", ", map {
        join " ", grep defined, @$_{qw(named var hasdefault default)}
      } @$params;
    }

    $sig_text .= ')';

    my $front = $self->_fp_arg_code_deparse($kw_text, $sig_text);

    $self->_transform_place_front_in_block($rest, $front);
    $sig->replace_text('');
  });
}

sub _parse_param_list {
  my ($self, $m, $param_text) = @_;
  return () unless $param_text;
  my $gr = $m->grammar_regexp;
  (my $capturing_re = $FPParamRE) =~ s/^(\s*)#/$1/gm;
  my @params;
  if( $param_text =~ /\A $capturing_re $gr/xg ) {
    push @params, +{ %+ };
  }
  while( $param_text =~ /\G (?&PerlOWS) [,] (?&PerlOWS) $capturing_re $gr/xg) {
    push @params, +{ %+ };
  }
  for my $param (@params) {
    if( exists $param->{other} ) {
      $param->{var} = delete $param->{other};
    }
  }
  @params;
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

sub _transform_place_front_in_block {
  my ($self, $rest, $front) = @_;
  $rest->transform_text(sub { s/^(\s*)\{/${1}{ ${front}/ });
}

1;
