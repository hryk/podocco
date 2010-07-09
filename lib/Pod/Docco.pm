package Pod::Docco;

use Any::Moose;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp qw(carp confess);
use File::Which qw{which};
use File::Slurp qw{slurp};
use PPI;
use IPC::Run qw(run timeout);
use Pod::Simple::XHTML;
use Data::Dumper;

use Pod::Docco::Layout;

carp "WARNING: Pygments not found. Using webservice." 
  unless which('pygmentize');

=head1 NAME

Pod::Docco

=head1 SYNOPSYS

    podocco lib/*.py

=head1 DESCRIPTION

Podocco is a Perl port of L<Docco|http://jashkenas.github.com/docco/>: the original
quick-and-dirty documentation generator.

It produces HTML that displays your comments
alongside your code. Comments are passed through L<Pod>, and code is passed through
Pyhmemnts syntax highlighting. This page is the result of Pod::Docco against its own
source file.

=cut

=head1 Methods

=cut

has 'filename' => (
  is       => 'rw',
  isa      => 'Str',
  required => 1
);

has 'options' => (
  is  => 'rw',
  isa => 'HashRef',
  required => 0,
  default => sub { {
    'language'      => 'perl',
    'comment_chars' => '#',
  } }
);

has 'sources' => (
  is  => 'rw',
  isa => 'ArrayRef',
  required => 0,
  default => sub { [] }
);

has 'sections' => (
  is  => 'rw',
  isa => 'ArrayRef',
  required => 0
);

has 'data' => (
  is  => 'rw',
  isa => 'PPI::Document',
  required => 0
);

sub BUILD {
  my $self = shift;
  my $data = PPI::Document->new($self->filename);
  $data->prune('PPI::Token::Comment');
  $self->data($data);
  $self->sections($self->highlight($self->split($self->parse)));
}

=head2 to_html

Generate HTML output for the entire document.

=cut

sub to_html {
  my $self = shift;
  Pod::Docco::Layout->new($self)->render();
}

=head2 highlight

Take the result of `split` and apply Markdown formatting to comments and
syntax highlighting to source code.

=cut

sub highlight {
  my $self   = shift;
  my $blocks = shift;
  my ($docs_blocks, $code_blocks) = @$blocks;
  my $boundary = "\n\n".$self->options->{comment_chars}."------BOUNDARY------\n\n";

  # translate pod to HTML by Pod::Simple::HTML
  my $pod = join("\n\n=head4 BOUNDARYBOUNDARY\n\n", @{$docs_blocks});
  my $pod_html = "";
  my $parser = Pod::Simple::XHTML->new();
  $parser->output_string(\$pod_html);
  $parser->html_header("");
  $parser->html_footer("");
  $parser->parse_string_document($pod);
  my $docs_html = [split(/\n<h4\sid=\"BOUNDARYBOUNDARY\d*\">BOUNDARYBOUNDARY<\/h4>\n/, $pod_html)];

  # highlight codeblocks.
  my $code_stream = join $boundary, @{$code_blocks};

  my $code_html = '';

  if (which("pygmentize")) {
    $code_html = $self->highlight_pygmentize($code_stream);
  } 
  else {
    confess 'TODO: implement `highlight_webservice`';
  }

  # remove BOUNDARY
  $code_html = [
  map { (my $x = $_ ) =~ s/\n*?<\/pre><\/div>\n//; $x }
  map { (my $x = $_ ) =~ s/\n*?<div\sclass=\"highlight\"><pre>//; $x}
  split(/\n<span\sclass=\"c.\">#------BOUNDARY------<\/span>\n/, $code_html)
  ];

  # zip code and docs.
  [ ( map { [$docs_html->[$_], $code_html->[$_]] } (0..$#$docs_html) ) ];
}

=head2 highlight with pygment

no documents.

=cut

sub highlight_pygmentize {
  my $self = shift;
  my $code = shift;

  my $lang = $self->options->{'language'};
  my $cmd  = ['pygmentize', '-l', $lang ,'-f', 'html'];
  my ($html, $err) = ('', '');

  run $cmd, \$code, \$html or confess "pygmentize : $!"; 

  return $html;
}

=head2 split_tuples

 Take the list of paired *sections* two-tuples and split into two
 separate lists: one holding the comments with leaders removed and
 one with the code blocks.

=cut

sub split {
  my $self     = shift;
  my $sections = shift;
  my ( $docs_blocks , $code_blocks ) = ([], []);
  for my $tuple (@$sections) {
    push @$docs_blocks, join( "\n",  @{$tuple->[0]} );
    push @$code_blocks, join("\n", map {
      # tabs = line.match(/^(\t+)/)
      # tabs ? line.sub(/^\t+/, '  ' * tabs.captures[0].length) : line
      /^(\t+)/;
      my $tab = length $1;
      if ($tab) {
        my $white = ' ' x $tab;
        s/^\t+/$white/;
      }
      else {
        $_;
      }
    } @{$tuple->[1]});
  }

  return [$docs_blocks, $code_blocks];
}

=head2 Internal Parsing and Highlighting

Parse the raw file data into a list of two-tuples. Each tuple has the
form `[$docs, $code]` where both elements are array-refs containing the
raw lines parsed from the input file. The first line is ignored if it
is a shebang line.

=cut

sub parse {
  my $self = shift;
  my $sections = [];
  my $start_lnum = 0;

  for my $pod (@{$self->data->find(sub{$_[1]->isa('PPI::Token::Pod')})}) {
    my ($docs, $code) = ([],[]);
    my $statements = $self->data->find(sub{
        ( $_[1]->line_number > $start_lnum )        and
        ( $_[1]->line_number < $pod->line_number )  and
        ( $_[1]->class eq 'PPI::Statement' )
      });

    if ($statements) {
      for my $state (@$statements) {
        my $text = $state->content."\n\n";
        push @$code, split("\n", $text);
      }
    }
    else {
      $code = [];
    }
    push @$docs, split("\n", $pod->content);
    push @$sections, [$docs,$code];
    $start_lnum = $pod->line_number;
  }

  return $sections;
}

no Any::Moose;
1;
