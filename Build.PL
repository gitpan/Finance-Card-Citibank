use Module::Build;

my $build = Module::Build->new(
	module_name		=> 'Finance::Card::Citibank',
	license			=> 'perl',
	create_readme	=> 1,
	requires		=> {
						'Carp'				=> 0,
						'WWW::Mechanize'	=> 1.00,
					   },
);
$build->create_build_script;

