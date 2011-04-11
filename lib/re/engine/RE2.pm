package re::engine::RE2;
use 5.010;

BEGIN {
  $re::engine::RE2::VERSION = "0.07";
}

use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN
{
    XSLoader::load __PACKAGE__, $VERSION;
}

sub import
{
    my $class = shift;

    $^H{regcomp} = ENGINE;

    if (@_) {
        my %args = @_;
        if (exists $args{"-max_mem"}) {
            re::engine::RE2::set_max_mem($args{"-max_mem"});
        }
    }
}

sub unimport
{
    delete $^H{regcomp}
        if $^H{regcomp} == ENGINE;
}

1;

__END__

=encoding utf8

=head1 NAME

re::engine::RE2 - RE2 regex engine

=head1 SYNOPSIS

    use re::engine::RE2;

    if ("Hello, world" =~ /Hello, (world)/) {
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

This module replaces perl's regex engine in a given lexical scope with RE2.

RE2 is a primarily DFA based regexp engine from Google that is very fast at
matching large amounts of text. However it does not support look behind and
some other Perl regular expression features. See
L<http://code.google.com/p/re2|RE2's website> for more information.

Fallback to normal Perl regexp is implemented by this module. If RE2 is unable
to compile a regexp it will use Perl instead, therefore features not
implemented by RE2 don't suddenly stop working, they will just use Perl's
regexp implementation.

=head1 METHODS

To access extra functionality of RE2 methods can be called on a compiled
regular expression (i.e. a C<qr//>).

=over 4

=item * C<possible_match_range([length = 10])>

Returns an array of two strings: where the expression will start matching and
just after where it will finish matching. See RE2's documentation on
PossibleMatchRange for further details.

Example:

    my($min, $max) = qr/^(a|b)/->possible_match_range;
    is $min, 'a';
    is $max, 'c';'

=back

=head1 PERFORMANCE

Performance is really the primary reason for using RE2, so here's some
benchmarks. Like any benchmark take them with a pinch of salt.

=head2 Simple matching

  my $foo = "foo bar baz";
  $foo =~ /foo/;
  $foo =~ /foox/;

On this very simple match RE2 is actually slower:

           Rate  re2   re
  re2  674634/s   -- -76%
  re  2765739/s 310%   --

=head2 URL matching

Matching C<m{([a-zA-Z][a-zA-Z0-9]*)://([^ /]+)(/[^ ]*)?|([^ @]+)@([^
@]+)}> against a several KB file:

        Rate    re   re2
  re  35.2/s    --  -99%
  re2 2511/s 7037%    --

=head2 Many alternatives

Matching a string against a regexp with 17,576 alternatives (C<aaa .. zzz>).

This uses trie matching on Perl (obviously RE2 does similar by default).

  $ perl misc/altern.pl
          Rate   re  re2
  re   52631/s   -- -91%
  re2 554938/s 954%   --

=head1 NOTES

=over 4

=item * No support for C<m//x>

The C</x> modifier is not supported. (There's no particular reason for this,
just RE2 itself doesn't support it). Fallback to Perl regexp will happen
automatically if C<//x> is used.

=item * "re2/dfa.cc:447: DFA out of memory: prog size xxx mem yyy"

If you attempt to compile a really large regular expression you may get this
error. RE2 has an internal limit on memory consumption for the DFA state
tables. By default this is 8 MiB.

If you need to increase this size then use the max_mem parameter:

  use re::engine::RE2 -max_mem => 8<<23; # 64MiB

=item * How do I tell if RE2 will be used?

See if your regexp is matching quickly or slowly ;).

Alternatively normal OO concepts apply and you may examine the object returned
by C<qr//>:

  use re::engine::RE2;

  ok qr/foo/->isa("re::engine::RE2");

  # Perl Regexp used instead
  ok not qr/(?<=foo)bar/->isa("re::engine::RE2");

=back

=head1 BUGS

Known issues:

=over 4

=item * Unicode handling

Currently the Unicode handling of re::engine::RE2 does not fully match Perl's
behaviour.

The UTF-8 flag of the regexp currently determines how the string is matched.
This is obviously broken, so will be fixed at some point.

=item * Final newline matching differs to Perl

  "\n" =~ /$/

The above is true in Perl, false in RE2. To work around the issue you can write
C<\n?\z> when you mean Perl's C<$>.

=back

Please report bugs via RT in the normal way. (Or a patch at
L<https://github.com/dgl/re-engine-RE2> would be most welcome.)

=head1 AUTHORS

David Leadbeater E<lt>dgl[at]dgl[dot]cxE<gt>

=head1 COPYRIGHT

Copyright 2010 David Leadbeater.

Based on L<re::engine::PCRE>:

Copyright 2007 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

The original version was copyright 2006 Audrey Tang
E<lt>cpan@audreyt.orgE<gt> and Yves Orton.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

(However the bundled copy of RE2 has a different copyright owner and is under a
BSD-like license, see F<re2/LICENSE>.)

=cut
