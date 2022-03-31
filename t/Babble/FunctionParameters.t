#!/usr/bin/env perl

use Test::More;
use Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters;
use Babble::Grammar;

use lib 't/lib';

my @cand = (
  [ 'method foo() { 42; }', {
      plain =>  q|sub foo { my $self = shift; 42; }|,
    },
  ],
  [ 'method foo( $bar ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; 42; }|,
      tp => q|sub foo { state $_check = Type::Params::compile( Type::Params::Invocant, Any ); my ($self, $bar) = $_check->(); }|,
    },
  ],
  [ 'method foo( $bar, $baz ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar, $baz) = @_; 42; }|,
    },
  ],
  [ 'around foo($bar, $baz) { 42; }', {
      plain =>  q|sub foo { my $orig = shift; my $self = shift; my ($bar, $baz) = @_; 42; }|,
      fp_deparse =>  q|sub foo { my($orig, $self) = splice(@_, 0, 2); my($bar, $baz) = @_; 42; }|,
    },
  ],
  [ 'classmethod foo($bar) { 42; }', {
      plain =>  q|sub foo { my $class = shift; my ($bar) = @_; 42; }|,
    },
  ],
  [ 'fun foo($bar) { 42; }', {
      plain =>  q|sub foo { my ($bar) = @_; 42; }|,
    },
  ],
  [ 'fun foo( Str $bar, Int $baz ) { 42; }', {
      plain =>  q|sub foo { my ($bar, $baz) = @_; 42; }|,
    },
  ],
  [ 'fun foo( $bar = "" ) { 42; }', {
      plain =>  q|sub foo { my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my($bar) = @_; $bar = "" if @_ < 1; 42; }|,
    },
  ],
  [ 'method foo( $bar = "" ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $self = shift(); my($bar) = @_; $bar = "" if @_ < 1; 42; }|,
    },
  ],
  [ 'method foo( :$bar, :$baz ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $self = shift(); my(%{__rest}) = @_; my $bar = ${__rest}{"bar"}; my $baz = ${__rest}{"baz"}; (%{__rest}) = (); 42; }|,
    },
  ],
  [ 'method foo( :$bar = 64, :$baz = 128 ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $self = shift(); my(%{__rest}) = @_; my $bar = exists ${__rest}{"bar"} ? delete ${__rest}{"bar"} : 64; my $baz = exists ${__rest}{"baz"} ? delete ${__rest}{"baz"} : 128; (%{__rest}) = (); 42; }|,
    },
  ],
  [ 'method foo( $class: :$bar = 64, :$baz = 128 ) { 42; }', {
      plain =>  q|sub foo { my $class = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $class = shift(); my(%{__rest}) = @_; my $bar = exists ${__rest}{"bar"} ? delete ${__rest}{"bar"} : 64; my $baz = exists ${__rest}{"baz"} ? delete ${__rest}{"baz"} : 128; (%{__rest}) = (); 42; }|,
    },
  ],
  [ 'method foo( :$bar = 64, :$baz = 128, @remaining ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $self = shift(); my(%{__rest}) = @_; my $bar = exists ${__rest}{"bar"} ? delete ${__rest}{"bar"} : 64; my $baz = exists ${__rest}{"baz"} ? delete ${__rest}{"baz"} : 128; my(@remaining) = %{__rest}; (%{__rest}) = (); 42; }|,
    },
  ],
  [ 'method foo( :$bar = 64, :$baz = 128, %opts ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; ...; 42; }|,
      fp_deparse => q|sub foo { my $self = shift(); my(%opts) = @_; my $bar = exists $opts{"bar"} ? delete $opts{"bar"} : 64; my $baz = exists $opts{"baz"} ? delete $opts{"baz"} : 128; 42; }|,
    },
  ],
);


my $fp = Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters->new(
  setup_package => 'FPSetup',
);

my $g = Babble::Grammar->new;

$fp->extend_grammar($g);

foreach my $cand (@cand) {
  my ($from, $to) = @$cand;

  subtest "Candidate: $from" => sub {
    subtest "Plain" => sub {
      TODO: {
      local $TODO = 'Generated transform not implemented yet'
        if $to->{plain} =~ /\Q...\E/;
      my $top = $g->match('Document' => $from);
      $fp->transform_to_plain_via_generate($top);
      is($top->text, $to->{plain}, "plain");
      }
    };

    subtest "Plain via Deparse" => sub {
      my $top = $g->match('Document' => $from);
      $fp->transform_to_plain_via_deparse($top);
      my $plain_to_deparse = $to->{plain};
      $plain_to_deparse =~ s/shift;/shift();/g;
      $plain_to_deparse =~ s/my \(/my(/g;
      is($top->text,
        exists $to->{fp_deparse}
          ? $to->{fp_deparse}
          : $plain_to_deparse,
        "deparse");
    };
  };

  #$fp->transform_to_type_params($top);
  #is($top->text, $to->{tp}, "type-params: ${from}");
}

done_testing;
