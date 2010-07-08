package Pod::Docco::Layout;
use Text::Xslate;

__END__
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
  : if ((scalar @$sources) > 1) {
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
    : if ((scalar @$sections) > 1) {
      : for $sections -> $section {
      <tr id='section-<: $section.num :>'>
        <td class=docs>
          <div class="octowrap">
            <a class="octothorpe" href="#section-<: $section.num :>">#</a>
          </div>
          <: $section.docs :>
        </td>
        <td class=code>
          <div class='highlight'><pre><: $section.code :></pre></div>
        </td>
      </tr>
      : }
    : }
  </table>
</div>
</body>
