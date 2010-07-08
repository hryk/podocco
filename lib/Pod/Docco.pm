package Pod::Docco;

use Any::Moose;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp qw(carp confess);
use File::Which qw{which};
use Pod::Docco::Layout;
use File::Slurp qw{slurp};
use PPI;
use IPC::Run qw(run timeout);

carp "WARNING: Pygments not found. Using webservice." unless which('pigmentize');

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
  requires => 1
);

has 'options' => (
  is  => 'rw',
  isa => 'HashRef',
  requires => 0,
  default => {
    'language'      => 'perl',
    'comment_chars' => '#',
  }
);

has 'sources' => (
  is  => 'rw',
  isa => 'ArrayRef',
  requires => 0,
  default => sub { [] }
);

has 'sections' => (
  is  => 'rw',
  isa => 'ArrayRef',
  requires => 0
);

has 'data' => {
  is  => 'rw',
  isa => 'PPI::Document',
  requires => 0
};

sub BUILD {
  my $self = shift;
  my $data = PPI::Document->($self->filename);
  $data->prune('PPI::Token::Comment');
  $self->data($data);
  $self->sections($self->highlight($self->parse));
}

# sub split {
#   my $self = shift;
#   my ($doc_blocks, $code_blocks) = ([],[]);
# }

=head2 highlight

Take the result of `split` and apply Markdown formatting to comments and
syntax highlighting to source code.

=cut

sub highlight {
  my $self   = shift;
  my $blocks = shift;
  my ($docs_blocks, $code_blocks) = @$blocks;
  my $code_stream = join "\n\n------BOUNDARY------\n\n", $code_blocks;
  my $code_html = ''; 
  if (which("pygmentize")) {
    $code_html = highlight_pygmentize($code_stream);
  } 
  else {
    confess 'TODO: implement `highlight_webservice`';
  }
}

=head2 highlight with pygment

no documents.

=cut

sub highlight_pygmentize {
  my $self = shift;
  my $code = shift;
  my $lang = $self->options->{'language'};
  my $cmd  = [qw/pygmentize -l $lang -f html/];
  my ($html, $err) = ('', '');
  
  run $cmd, \$in, \$html, \$err or confess "pygmentize : $?"; 

  return $html;
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
  my ($docs, $code) = ([],[]);
  my $start_lnum = 0;

  for my $pod ($self->data->find(sub{$_[1]->isa('PPI::Token::Pod')})) {

    my $statements = $self->data->find(sub{
        ( $_[1]->line_number > $start_lnum )             and
        ( $_[1]->line_number < ($pod->line_number - 1) ) and
        ( $_[1]->class eq 'PPI::Statement' )
      });

    for my $state (@$statements) {
      my $text = $state->content()."\n";
      push @$code, split("\n", $text);
    }

    push @$docs, split("\n", $pod->content);
    puths @$sections, [$docs,$code];
  }

  return $sections;
}

no Any::Moose;

1;
