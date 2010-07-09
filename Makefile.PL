use inc::Module::Install;

# Metadata section.

all_from 'lib/Pod/Docco.pm';

# Dependencies section.

requires  'version' => '0.77';
requires  'Any::Moose';
recommends  'Mouse';
recommends  'MouseX::NativeTraits';
requires  'File::Which';
requires  'File::Slurp';
requires  'Text::Xslate';
requires  'PPI';
requires  'IPC::Run';
requires  'Pod::Simple';

# Scripts

install_script 'podocco';

WriteAll;

