use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Posy-Plugin-BinFile',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/Posy/Plugin/BinFile.pm',
	requires            => {
	'Posy' => 0.70,
	'Posy::Plugin::FileStats' => 0.40,
	},
    build_requires => {
        'Test::More' => 0,
    },
);

$builder->create_build_script();
