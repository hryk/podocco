package Pod::Docco::Layout;
use Moose;
use File::Slurp qw/slurp/;
use Text::Xslate qw/mark_raw/;

has 'doc' => (
  is       => 'rw',
  isa      => 'Object',
  required => 1
);

has 'template' => (
  is  => 'rw',
  isa => 'Str',
#  lazy => 1,
#  default => sub { 
#    no warnings;
#    slurp(\*DATA);
#  }
);

has 'template_vars' => (
  is      => 'rw',
  isa     => 'HashRef',
  traits    => ['Hash'],
  default => sub { {} },
  handles => {
    set_var => 'set',
    get_var => 'get',
    has_var => 'exists'
  }
);

around "BUILDARGS" => sub {
  my $orig  = shift;
  my $class = shift;

  if (@_ == 1) {
    return $class->$orig(doc => $_[0]);
  } 
  else {
    return $class->$orig(@_);
  }
};

# call after construction.
sub BUILD {
  my $self = shift; 
  my ($volume,$directories,$file) = File::Spec->splitpath( $self->doc->filename );

  $self->set_var('title', $file);

  my ( $sources_exist , $sources ) = (0, []);
  if (scalar @{$self->doc->sources} > 1) {
    $sources_exist = 1;
    for my $source ( @{$self->doc->sources} ) {
      my ($v,$d,$f) = File::Spec->splitpath( $source );
      my $splited_name = [split(/\./, $source)];
      push @$sources, {
        path     => $source,
        basename => $f,
        url      => (join '.', @{$splited_name}[0..($#$splited_name-1)]).'.html',
      }
    }
  }
  $self->set_var('sources?', $sources_exist);
  $self->set_var('sources',  $sources);

  my $num = 0;
  my $sections = [];
  for my $section (@{$self->doc->sections}) {
    push @{$sections}, {
      docs => mark_raw($section->[0]),
      code => mark_raw($section->[1]),
      num  => ($num++)
    }
  }
  $self->set_var('sections', $sections);
  my $template_string = slurp(\*DATA);
  $self->template($template_string);
}

sub render {
  my $self = shift;
  my $tx = Text::Xslate->new();
  $tx->render_string($self->template, $self->template_vars);
}

1;

__DATA__

<!DOCTYPE html>
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title><: $title :></title>
<link rel="stylesheet" href="http://jashkenas.github.com/docco/resources/docco.css">
</head>
<body>
<div id='container'>
<div id="background"></div>
: if ($sources > 1) {
<div id="jump_to">
Jump To &hellip;
<div id="jump_wrapper">
<div id="jump_page">
: for $sources -> $code {
<a class="source" href="<: $code.url :>"><: $code.basename :></a>
: }
</div>
</div>
</div>
: }
<table cellspacing=0 cellpadding=0>
<thead>
<tr>
<th class=docs><h1><: $title :></h1></th>
<th class=code></th>
</tr>
</thead>
<tbody>
: if ($sections > 1) {
: for $sections -> $section {
<tr id='section-<: $section.num :>'>
  <td class=docs>
    <div class="octowrap">
    <a class="octothorpe" href="#section-<: $section.num :>">#</a>
    </div>
    <: $section.docs :>
  </td>
  <td class=code>
    <div class='highlight'>
      <pre><: $section.code :></pre>
    </div>
  </td>
</tr>
: }
: }
</table>
</div>
</body>
