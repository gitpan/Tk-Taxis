use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile
(
	'NAME'          => 'Tk::Taxis',
	'VERSION_FROM'  => 'Taxis.pm',
	'PREREQ_PM'     => { Tk => 800.024 },
	'EXE_FILES'     => [ 'eg/woodlice.pl' ],
    (
    	$] >= 5.005 ?
     		(
				ABSTRACT_FROM => 'Taxis.pm',
				AUTHOR        => 'Steve Cook <steve@steve.gb.com>'
			) : 
				()
	),
);
