#!/usr/bin/env perl

use Test::More;
use Dist::Zilla::PluginBundle::Author::ZMUGHAL::Babble::FunctionParameters;
use Babble::Grammar;

use lib 't/lib';

my @cand = (
  [ 'method foo() { 42; }', {
      plain =>  q|sub foo { my $self = shift; 42; }|,
      #fp_deparse => q|sub foo { my $self = shift(); 42; }|,
    },
  ],
  [ 'method foo( $bar ) { 42; }', {
      tp => q|sub foo { state $_check = Type::Params::compile( Type::Params::Invocant, Any ); my ($self, $bar) = $_check->(); }|,
      plain =>  q|sub foo { my $self = shift; my ($bar) = @_; 42; }|,
    },
  ],
  [ 'method foo( $bar, $baz ) { 42; }', {
      plain =>  q|sub foo { my $self = shift; my ($bar, $baz) = @_; 42; }|,
    },
  ],
  [ 'around foo($bar, $baz) { 42; }', {
      plain =>  q|sub foo { my $orig = shift; my $self = shift; my ($bar, $baz) = @_; 42; }|,
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
      plain =>  q|sub foo { my ($bar) = @_; 42; }|,
      fp_deparse => q|sub foo { my($bar) = @_; $bar = "" if @_ < 1; 42; }|,
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
      my $top = $g->match('Document' => $from);
      $fp->transform_to_plain($top);
      is($top->text, $to->{plain}, "plain");
    };

    subtest "Plain via Deparse" => sub {
      plan skip_all => 'deparse does not currently support runtime'
        if $from =~ /\A around/x;
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
