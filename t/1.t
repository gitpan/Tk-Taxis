use Test::More qw( no_plan );
BEGIN { use_ok('Tk::Taxis') };

use Tk;
my $mw = new MainWindow;

diag "\nDuring these tests, some windows may appear temporarily";

# create with defaults
my $taxis = $mw->Taxis();
ok( ref $taxis eq "Tk::Taxis" );
ok( $taxis->height() == 400 );
ok( $taxis->cget( -width ) == 400 );
my $default_pref = $taxis->cget( -preference );
ok( $default_pref->[0] == 100 );
ok( $default_pref->[1] == 100 );
ok( $taxis->cget( -population ) == 20 );
ok( $taxis->cget( -tumble ) == 0.03 );
ok( $taxis->cget( -speed ) == 0.006 );
ok( $taxis->cget( -images ) eq "woodlice" );
my $default_fill = $taxis->cget( -fill );
ok( $default_fill->[0][0] eq 'white' );
ok( $default_fill->[0][1] eq 'gray' );
ok( $default_fill->[1][0] eq 'white' );
ok( $default_fill->[1][1] eq 'gray' );
my $calc = $taxis->cget( -calculation );
ok( ref $calc eq "CODE" );

# create with options
$taxis = $mw->Taxis
	( -width => 100, -height => 200, -population => 50, -tumble => 0.02,
	  -speed => 0.05, -images => 'bacteria' );
ok( ref $taxis eq "Tk::Taxis" );
ok( $taxis->cget( -height ) == 200 );
ok( $taxis->height() == 200 );
ok( $taxis->cget( -width ) == 100 );
ok( $taxis->width() == 100 );
ok( $taxis->cget( -population ) == 50 );
ok( $taxis->population() == 50 );
ok( $taxis->cget( -tumble ) == 0.02 );
ok( $taxis->tumble() == 0.02 );
ok( $taxis->cget( -speed ) == 0.05 );
ok( $taxis->speed() == 0.05 );
ok( $taxis->cget( -images ) eq 'bacteria' );
ok( $taxis->images() eq 'bacteria' );

# images
$taxis->configure( -images => 'woodlice' );
my $img = $taxis->cget( -images );
ok( $img eq 'woodlice' );
ok ( $taxis->image_height() == 50 );
ok ( $taxis->image_width() == 50 );

# preference
$taxis->configure( -preference => [ 0.1, -50 ] );
my $pref = $taxis->cget( -preference );
ok( $pref->[0] == 1 );
ok( $pref->[1] == -50 );
$taxis->configure( -preference => [ 20 ] );
$pref = $taxis->cget( -preference );
ok( $pref->[0] == 20 );
ok( $pref->[1] == 1 );
$taxis->configure( -preference => 200 );
$pref = $taxis->cget( -preference );
ok( $pref->[0] == 200 );
ok( $pref->[1] == 1 );

# tumble
$taxis->tumble( 0.5 );
my $tumble = $taxis->cget( -tumble );
ok( $tumble == 0.5 );
$taxis->configure( -tumble => 20 );
$tumble = $taxis->tumble();
ok( $tumble == 1 );
$taxis->configure( -tumble => -20 );
$tumble = $taxis->cget( -tumble );
ok( $tumble == 0 );

# speed
$taxis->configure( -width => 30 ); 
$taxis->configure( -height => 40 ); 
$taxis->configure( -speed => 0.06 );
ok( $taxis->cget( -speed ) == 0.06 );
$taxis->configure( -speed => 0.02 );
ok( $taxis->cget( -speed ) == 0.04 );

# calculation
my $coderef = $taxis->cget( -calculation );
$taxis->configure( -calculation => sub { return 1, 1000 } );
my ( $x, $y ) = $taxis->cget( -calculation )->();
ok( $x == 1 );
ok( $y == 1000 );
$taxis->configure( -calulation => $coderef );

# population
$taxis->population( 100 );
my %c = $taxis->cget( -population );
ok( $c{ total } == 100 ); 
$taxis->population( -10 );
%c = $taxis->cget( -population );
ok( $c{ total } == 10 ); 
ok( $c{ bottom } == $c{ bottom_left } + $c{ bottom_right } ); 
ok( $c{ top } == $c{ top_left } + $c{ top_right } ); 
ok( $c{ right } == $c{ bottom_right } + $c{ top_right } ); 
ok( $c{ left } == $c{ bottom_left } + $c{ top_left } ); 
ok( $c{ total } == $c{ bottom } + $c{ top } ); 
ok( $c{ total } == 10 ); 
ok( $taxis->cget( -population ) == 10 );

# fill
$taxis->configure( -fill => '#667766' );
my $fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq '#667766' );
ok( $fill->[0][1] eq '#667766' );
ok( $fill->[1][0] eq '#667766' );
ok( $fill->[1][1] eq '#667766' );
$taxis->configure( -fill => [ 'red', 'blue' ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red' );
ok( $fill->[0][1] eq 'blue' );
ok( $fill->[1][0] eq 'red' );
ok( $fill->[1][1] eq 'blue' );
$taxis->configure( -fill => [ 'red', 'blue' ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red' );
ok( $fill->[0][1] eq 'blue' );
ok( $fill->[1][0] eq 'red' );
ok( $fill->[1][1] eq 'blue' );
$taxis->configure( -fill => [ [ 'red', 'yellow' ], [ 'blue', '#888888' ] ] );
$fill = $taxis->cget( -fill );
ok( $fill->[0][0] eq 'red' );
ok( $fill->[0][1] eq 'yellow' );
ok( $fill->[1][0] eq 'blue' );
ok( $fill->[1][1] eq '#888888' );

# taxis methods
my $return = $taxis->taxis();
ok( ref $return eq 'Tk::Taxis' );
$return = $taxis->refresh();
ok( ref $return eq 'Tk::Taxis' );

# critters
$taxis = $mw->Taxis();
my $critter = $taxis->{ critters }[ 1 ];
my @pos = $critter->get_pos();
ok( defined $pos[0] );
ok( defined $pos[1] );
my $obj = $critter->move();
ok( ref $obj eq 'Tk::Taxis::Critter' );
$obj = $critter->randomise();
ok( ref $obj eq 'Tk::Taxis::Critter' );
my %b = $critter->get_boundries();
ok( $b{min_x} == 25 ); 
ok( $b{min_y} == 25 ); 
ok( $b{max_x} == 375 ); 
ok( $b{max_y} == 375 ); 
ok( $b{height} == 400 ); 
ok( $b{width} == 400 ); 
$critter->set_orient('s');
ok( $critter->get_orient() eq 's' );
$critter->{ direction } = 0.01;
$critter->set_orient();
ok( $critter->get_orient() eq 'e' );
