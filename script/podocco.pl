#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use File::Spec;
use File::Path qw/mkpath/;
use Pod::Docco;

my $options = {
  language => 'perl',
  comment_chars => '#',
  output => ''
};

my $help = 0;

GetOptions(
  "language=s"      => \$options->{'language'},
  "comment-chars=s" => \$options->{'comment_chars'},
  "output=s"        => \$options->{'output'},
  "help"            => \$help
);

pod2usage(0) if $help;

my @sources;
if (scalar @ARGV > 0) {
  @sources = @ARGV;
}
else {
  pod2usage({
   -message => 'Podocco : File empty.',
   -exitval => 1,
   -verbose => 1,
  });
}

my $outdir = delete $options->{output};
for my $source (@sources) {
  my $podocco = Pod::Docco->new(
    filename => $source,
    options  => $options,
    sources  => \@sources,
  );
  my $splited_name = [split(/\./, $source)];
  my $dest = File::Spec->catfile(
    $outdir,
    ((( (scalar @{$splited_name}) > 0) ?
      join('.', @{$splited_name}[0..($#$splited_name-1)]) : $source).".html")
  );

  print "podocco: $source -> $dest\n";
  my $paths = [File::Spec->splitdir($dest)];
  mkpath(File::Spec->join(@{$paths}[0..($#$paths-1)])); 
  open my $out, ">$dest" or die "dest open failed : $!";
  print $out $podocco->to_html;
  close $out;
}

__END__

=head1 NAME
  
  podocco - Generate literate-programming-style documentation for Perl.

=head1 SYNOPSYS

=item B<podocco>

[B<--help>]
[B<--language>S< >I<language>]
[B<--comment-chars> I<chars>]
[B<--output>S< >I<outfile>]
I<file>

=back

=head1 OPTIONS AND ARGUMENTS

=over 8

=item B<--help>

=item B<--language>S< >I<language>

=item B<--comment-chars> I<chars>

=item B<--output>S< >I<outfile>

=item I<file>

=back

=head1 SEE ALSO

L<Pod::Docco>

=head1 AUTHOR

Please report bugs using L<http://rt.cpan.org>.

Hiroyuki Nakamura E<lt>hello@hryk.infoE<gt>

=cut
