use Test::More qw( no_plan );
BEGIN { use_ok('Tk::Taxis') };

# some rather cursory tests, since we can't actually see them move!

use Tk;

diag "\nDuring these tests, some windows may appear temporarily";

# create
my $mw = new MainWindow;
my $taxis = $mw->Taxis( -width => 100, -height => 200, -population => 50 );
ok( ref $taxis eq "Tk::Taxis" );

# cget
my $width = $taxis->cget( -width );
ok(  $width == 100 );

# methods
my $population = $taxis->population( 10 );
ok( $population == 10 );

# default
my $speed = $taxis->cget( -speed );
ok( $speed == 0.006 );

# configure
$taxis->configure( -images => 'bacteria' );
my $img = $taxis->cget( -images );
ok( $img eq "bacteria" );

# sanity checking
$taxis->configure( -preference => 0 );
my $pref = $taxis->cget( -preference );
ok( $pref == 1 );

# taxis
$taxis->population( 100 );
for ( 1 .. 10 )
{
	$taxis->taxis();
}
my ( $l, $r ) = $taxis->cget( -population );
my $ratio = $l / $r;
diag "\nIf this test fails, do not panic, it is testing a stochastic model that may rarely give wrong answers";
ok( abs ( $ratio - 1 ) < 0.5 ); # more bias than this would be odd

