package Tk::Taxis;

use 5.008;
use strict;
use warnings::register;

use Carp;

our $VERSION = '1.04';

################################## defaults ####################################

use constant WIDTH      => 400;
use constant HEIGHT     => 200;
use constant POPULATION => 10;
use constant PREFERENCE => 100;
use constant TUMBLE     => 0.03;
use constant SPEED      => 0.006;
use constant IMAGES     => "woodlice";
use constant LEFT_FILL  => "white";
use constant RIGHT_FILL => "gray";

################################### widget #####################################

use Tk qw( DoOneEvent DONT_WAIT );
use Tk::Taxis::Critter;

require Tk::Frame;
our @ISA = ( 'Tk::Frame' );

Tk::Widget->Construct( 'Taxis' );

sub Populate
{   
	my ( $taxis, $options ) = @_;
	
	my $canvas = $taxis->Canvas();
	$taxis->Advertise( 'canvas' => $canvas );
	$canvas->pack();
	
	my $images = ( delete $options->{ -images } ) || IMAGES;
	$taxis->images( $images );

	$taxis->preference( delete $options->{ -preference }  || PREFERENCE );
	$taxis->tumble(     delete $options->{ -tumble }      || TUMBLE );
	$taxis->speed(      delete $options->{ -speed }       || SPEED );

	my $width      = ( delete $options->{ -width } )      || WIDTH;
	my $height     = ( delete $options->{ -height } )     || HEIGHT;
	my $population = ( delete $options->{ -population } ) || POPULATION;
	my $left_fill  = ( delete $options->{ -left_fill } )  || LEFT_FILL;
	my $right_fill = ( delete $options->{ -right_fill } ) || RIGHT_FILL;
	$taxis->_draw_arena
	( { 
			-width      => $width, 
			-height     => $height,
			-left_fill  => $left_fill,
			-right_fill => $right_fill,
			-population => $population,
	} );
		# we do it like this, rather than calling width and height separately
		# to avoid refreshing the canvas repeatedly on initialisation
	
	$taxis->ConfigSpecs
	(
		-population  => [ 'METHOD', 'population', 'Population', undef ],
		-preference  => [ 'METHOD', 'preference', 'Preference', undef ],
		-tumble      => [ 'METHOD', 'tumble',     'Tumble',     undef ],
		-speed       => [ 'METHOD', 'speed',      'Speed',      undef ],
		-images      => [ 'METHOD', 'images',     'Images',     undef ],
		-left_fill   => [ 'METHOD', 'left_fill',  'LeftFill',   undef ],
		-right_fill  => [ 'METHOD', 'right_fill', 'RightFill',  undef ],
		-width       => [ 'METHOD', 'width',      'Width',      undef ],
		-height      => [ 'METHOD', 'height',     'Height',     undef ],
		DEFAULT      => [ $canvas ],
	);
	$taxis->SUPER::Populate( $options );
	$taxis->Delegates( DEFAULT => $canvas );
}

################################### images #####################################

sub images
{
	my ( $taxis, $images ) = @_;
	if ( $images )
	{
		$taxis->{ images } = $images;
		unless ( $taxis->{ image_bank }{ $images } )
		{
			$taxis->{ image_bank }{ $images } =
			{
				n  => $taxis->Photo( -file => $taxis->_find_image( "n.gif"  ) ),
				ne => $taxis->Photo( -file => $taxis->_find_image( "ne.gif" ) ),
				e  => $taxis->Photo( -file => $taxis->_find_image( "e.gif"  ) ),
				se => $taxis->Photo( -file => $taxis->_find_image( "se.gif" ) ),
				s  => $taxis->Photo( -file => $taxis->_find_image( "s.gif"  ) ),
				sw => $taxis->Photo( -file => $taxis->_find_image( "sw.gif" ) ),
				w  => $taxis->Photo( -file => $taxis->_find_image( "w.gif"  ) ),
				nw => $taxis->Photo( -file => $taxis->_find_image( "nw.gif" ) ),
				0  => $taxis->Photo(),
			};
		}
		$taxis->image_height
		( 
			$taxis->{ image_bank }{ $images }{ n }->height()  || 50
		);	
		$taxis->image_width
		( 
			$taxis->{ image_bank }{ $images }{ n }->width()  || 50
		);	
	}
	return $taxis->{ images };
}

sub _find_image
{
	my ( $taxis, $file ) = @_;
	my $dir = $taxis->{ images };
	my $found;
	if ( my ( $path ) = $dir =~ /^\@(.*)$/ )
	{
		$found = ( grep { -e $_ } "$path/$file" )[ 0 ];
		carp "No such file $path/$file" unless $found;
	}
	else
	{
		$found = 
		   ( grep { -f $_ } map { "$_/Tk/Taxis/images/$dir/$file" } @INC )[ 0 ];
		carp "No such file \@INC/Tk/Taxis/images/$dir/$file" unless $found;
	}
	return $found;
}

sub _create_critter_image
{
	my ( $taxis, $critter ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	my @pos    = $critter->get_pos();
	my $id     = $critter->get_id();
	my $image  = 
		$taxis->{ image_bank }{ $taxis->{ images } }{ $critter->get_orient() };
	if ( defined $id )
	{
		$canvas->coords( $id, $pos[ 0 ], $pos[ 1 ] );
		$canvas->itemconfigure( $id, -image => $image );
	}
	else
	{
		my $id = $canvas->create
			( 'image', $pos[ 0 ], $pos[ 1 ], 
				-anchor => 'center', -image  => $image );
		$critter->set_id( $id );
	}
	return $taxis;
}

sub _hide_critter_image
{
	my ( $taxis, $critter ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	my $id     = $critter->get_id();
	my $image  = $taxis->{ image_bank }{ $taxis->{ images } }{ 0 };
	if ( defined $id )
	{
		$canvas->itemconfigure( $id, -image => $image );
	}
	return $taxis;
}

sub image_height
{
	my ( $taxis, $image_height ) = @_;
	if ( defined $image_height )
	{
		$taxis->{ image_height } = $image_height;
	}
	return $taxis->{ image_height };
}

sub image_width
{
	my ( $taxis, $image_width ) = @_;
	if ( defined $image_width )
	{
		$taxis->{ image_width } = $image_width;
	}
	return $taxis->{ image_width };
}

################################## critters ####################################

sub preference
{
	my ( $taxis, $preference ) = @_;
	if ( defined $preference )
	{
		unless ( abs $preference > 1 )
		{
			carp "Preference too low, setting to minimum value of 1"
				if warnings::enabled();
			$preference = 1; 
				# or exceptions will occur: we divide the tumble frequency by
				# this number to yield the preference. This way, preferences 
				# between -1 and +1 all yield indifference
		}
		$taxis->{ preference } = $preference;
	}
	return $taxis->{ preference };
}

sub tumble
{
	my ( $taxis, $tumble ) = @_;
	if ( defined $tumble )
	{	
		$taxis->{ tumble } = $tumble;
	}
	return $taxis->{ tumble };
}

sub speed
{
	my ( $taxis, $speed ) = @_;
	if ( defined $speed )
	{
		my $canvas = $taxis->Subwidget( 'canvas' );
		my $max_x  = $canvas->cget( -width );
		my $min_speed = 2 / $max_x;
		if ( $speed < $min_speed )
		{
			carp "Speed to low, setting to minimum value of $min_speed"
				if warnings::enabled();
			$speed = $min_speed;
				# or they sit there and spin
		}
		$taxis->{ speed } = $speed;
	}
	return $taxis->{ speed };
}

#################################### taxis #####################################

sub taxis
{
	my ( $taxis, $options ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	if ( $taxis->{ critters } )
	{
		my $critter;
		for my $i ( 1 .. $taxis->{ population } )
		{
			$critter = $taxis->{ critters }[ $i ];
			$critter->move();
			$taxis->_create_critter_image( $critter );
		}
		DoOneEvent( DONT_WAIT ); 
	}
	return $taxis;
}

#################################### arena #####################################

sub population
{
	my ( $taxis, $population ) = @_;
	if ( defined $population )
	{
		$taxis->{ population } = abs $population;
			# we never know how stupid people can be
		$taxis->_draw_arena();
	}
	if ( wantarray )
	{
		my $canvas = $taxis->Subwidget( 'canvas' );
		my ( $left, $right ) = ( 0, 0 );
		for my $i ( 1 .. $taxis->{ population } )
		{
			${ $taxis->{ critters } }[ $i ]{ pos }[ 0 ] 
				<= $canvas->cget( -width ) / 2 ? 
					$left++ : 
						$right++;
		}
		return $left, $right;
	}
	else
	{
		return $taxis->{ population };
	}
}

sub width
{
	my ( $taxis, $width ) = @_;
	if ( $width )
	{
		$taxis->{ width } = $width;
		$taxis->_draw_arena();
	}
	$taxis->{ width };
}

sub height
{
	my ( $taxis, $height ) = @_;
	if ( $height )
	{
		$taxis->{ height } = $height;
		$taxis->_draw_arena();
	}
	$taxis->{ height };	
}

sub left_fill
{
	my ( $taxis, $left_fill ) = @_;
	if ( $left_fill )
	{
		$taxis->{ left_fill } = $left_fill;
		$taxis->_draw_arena();
	}
	$taxis->{ left_fill };	
}	

sub right_fill
{
	my ( $taxis, $right_fill ) = @_;
	if ( $right_fill )
	{
		$taxis->{ right_fill } = $right_fill;
		$taxis->_draw_arena();
	}
	$taxis->{ right_fill };	
}

sub _draw_arena
{
	my ( $taxis, $options ) = @_;
	my $canvas = $taxis->Subwidget( 'canvas' );
	if ( my $width = delete $options->{ -width } )
	{
		$canvas->configure( -width => $width );
		$taxis->{ width } = $width;
	}
	if ( my $height = delete $options->{ -height } )
	{
		$canvas->configure( -height => $height );
		$taxis->{ height } = $height;
	}
	if ( my $population = delete $options->{ -population } )
	{
		$taxis->{ population } = $population;
	}	
	if ( my $left_fill = delete $options->{ -left_fill } )
	{
		$taxis->{ left_fill } = $left_fill;
	}	
	if ( my $right_fill = delete $options->{ -right_fill } )
	{
		$taxis->{ right_fill } = $right_fill;
	}	
	my $max_x  = $taxis->{ width };
	my $max_y  = $taxis->{ height };
	if ( $taxis->{ arena } )
	{
		my ( $left, $right ) = @{ $taxis->{ arena } };
		$canvas->coords
			( $left, 0, 0, $max_x / 2, $max_y );
		$canvas->itemconfigure( $left, -fill => $taxis->{left_fill} );
		$canvas->coords
			( $right, $max_x / 2, 0, $max_x, $max_y);		
		$canvas->itemconfigure( $right, -fill => $taxis->{right_fill} );
	}
	else
	{
		my $left = $canvas->create
			( 'rectangle', 0, 0, $max_x / 2, $max_y, 
				-fill => $taxis->{left_fill} );
		my $right = $canvas->create
			( 'rectangle', $max_x / 2, 0, $max_x, $max_y, 
				-fill => $taxis->{right_fill} );
		$taxis->{ arena } = [ $left, $right ];
	}
	my $i;
	for ( $i = 1 ; $i <= $taxis->{ population } ; $i++ )
	{
		my $critter = $taxis->{ critters }[ $i ];
		unless ( $critter )
		{
			$critter = Tk::Taxis::Critter->new( -taxis => $taxis );
			$taxis->{ critters }[ $i ] = $critter;
		}
		$critter->randomise();
		$taxis->_create_critter_image( $critter );
	}
	for my $j ( $i .. @{ $taxis->{ critters } } - 1  )
	{
		
		# We don't delete the critters from the critters arrayref, 
		# we just keep track of the current population size, and 
		# grow this as appropriate; we only hide their images from view in the 
		# canvas. We do this because we cannot satifactorily 
		# delete images from canvases, as this appears to causes memory leakage
		# even if we delete all references, and call the delete method on all 
		# widgets. I presume this is a bug in Tk::Canvas, as it works for other 
		# imaged widgets. This way we only get as big as the largest population 
		# called during the life of the script.
		
		my $critter = $taxis->{ critters }[ $j ];
		$taxis->_hide_critter_image( $critter );
	}
	DoOneEvent( DONT_WAIT ); 
	return $taxis;
}

1;

__END__

=head1 NAME

Tk::Taxis - Perl extension for simulating biological taxes

=head1 SYNOPSIS

  use Tk::Taxis;
  my $taxis = $mw->Taxis( -width => 200, -height => 100 )->pack();
  $taxis->configure( -population => 20 );
  $taxis->taxis() while 1;

=head1 ABSTRACT

Simulates the biological movement called taxis

=head1 DESCRIPTION

Organisms such as bacteria respond to gradients in chemicals, light, I<etc>, by 
a process called taxis ('movement'). This module captures some of the spirit of 
this model of organismal movement. Bacteria are unable to measure differential
gradients of chemicals along the length of their cells. Instead, they measure
the concentration at a given point, move a little, measure it again, then if
they find they are running B<up> a concentration gradient, they reduce their 
tumbling frequency (the probability that they will randomly change direction). 
In this way, they effect a random walk that is biased up the gradient. 

=head2 METHODS

C<Tk::Taxis> is a composite widget, so to invoke a new instance, you need to 
call it in the usual way...

  my $taxis = $mw->Taxis( -option => value )->pack();
  $taxis->configure ( -option => value );
  my $number = $taxis->cget( -option );

or similar. This widget is a composite, based on Frame and inplementing a 
Canvas. Configurable options are mostly forwarded to the Canvas subwidget, which
be directly accessed by the C<Subwidget('canvas')> method. Options specific to
the C<Tk::Taxis> widget are listed below. If you try to pass in values too low 
or high (as specified below), the module will C<carp> (if C<warnings> are 
enabled) and use a default minimum or maximum instead. These options can be set 
in the constructor, and get/set by the standard C<cget> and C<configure> 
methods.

=over 4

=item * C<-width>

Sets the width of the taxis arena. Defaults to 400.

=item * C<-height>

Sets the height of the taxis arena. You are advised to set the height and width
when constructing the widget, rather than configuring them after the event, as
this will result in repeated redrawings of the canvas. Defaults to 200.

=item * C<-tumble>

This sets the default tumble frequency, I<i.e.> the tumble frequency when the 
critters are moving B<down> the concentration gradient. No sanity checking is 
done, but a tumble frequency of 1 is unlikely to get you very far. Defaults to 
0.03.

=item * C<-preference>

This takes a numeric argument indicating the preference the critters have for
the right hand side of the taxis arena. When the critters are moving B<up> the
gradient (to the right), their tumble frequency will be equal to the default 
tumble divided by the absolute value of this number. Negative preferences will 
reverse the taxis. Values in the interval [-1, +1] will be truncated to 1, since
the tumble frequency does not increase above the default in reality (this is not
how negative taxis is achieved). Defaults to 100.

=item * C<-speed>

This sets the speed of the critters. When the critters are moved, the run length
is essentially set to C<rand( width_of_canvas ) * speed * cos rotation>. If 
there is no rotation, the maximum run length will be simply be the width of the 
canvas multiplied by the speed. If you try to set a speed lower than C<2 / 
width_of_canvas>, it will be ignored, and this mimimum value will be used 
instead otherwise your critters, moving a fractional number of pixels, will sit 
there and spin like tops. Defaults to 0.006.

=item * C<-population>

This takes an integer argument to configure the size of the population. If 
C<cget( -population )> is called, the return vale depends on context: the
total population is returned in scalar context, but in list context, the 
numbers of critters on the left and right are returned in that order. Defaults
to 10.

=item * C<-images>

This takes a string argument which is the path to a directory containing images
to display as critters. If this begins with an C<@> sign, this will be taken to 
be a real path. Otherwise, it will be taken to be a default image set. This may
currently be 'woodlice' or 'bacteria' (these images are located in directories 
of the same name in C<@INC/Tk/Taxis/images/>). There must be eight images, named 
C<n.gif>, C<ne.gif>, C<e.gif>, C<se.gif>, C<s.gif>, C<sw.gif>, C<w.gif> and 
C<nw.gif>, each showing the critter in a different orientation (n being 
vertical, e being pointing to the right, I<etc>).  Defaults to 'woodlice'.

=item * C<-left_fill>

This takes an colour string argument (I<e.g.> "red" or "#00FF44") to set the
fill colour of the left hand side of the arena.

=item * C<-right_fill>

This takes an colour string argument to set the fill colour of the right hand 
side of the arena.

=back

These options can also all be called as similarly named methods. There is also 
one additional public method...

=over 4

=item * C<taxis()>

This executes one cycle of the taxis simulation. Embed calls to this in a 
C<while> loop to run the simulation. See the script C<eg/woodlice.pl> for an 
example of how to embed an interruptable loop within a handrolled main-loop, or
CAVEATS below.

=back

Two final methods available are C<image_height> and C<image_width>, which
get/set the height and width of the image used as a critter. It is inadvisable
to set these, but the C<Tk::Taxis::Critter> class requires read-only access to 
them. 

=head1 SCRIPTS

The module installs a script called C<woodlice.pl> in your perl's C<bin> 
directory which is a fully functional simulation demonstrating the use of the
module.

=head1 CAVEATS

Those used to writing...

  MainLoop();

in every C<Tk> script should note that because the simulation requires its 
B<own> event loop I<within> the event loop of the main program, this will not 
work out of the box. The best solution I have found is this...

  # import some semantics 
  use Tk qw( DoOneEvent DONT_WAIT );
  use Tk::Taxis;
  use Time::HiRes;
  my $mw = new MainWindow;
  my $taxis = $mw->Taxis()->pack();

  # this tells us whether we are running the simulation or not
  my $running = 1;
  
  # minimum refresh rate
  my $refresh = 0.02; # 20 ms
  
  # home-rolled event loop
  while ( 1 )
  {
    my $finish = $refresh + Time::HiRes::time;
    $taxis->taxis() if $running;
    while ( Time::HiRes::time < $finish  )
      # take up some slack time if the loop executes very quickly
    { 
      DoOneEvent( DONT_WAIT );
    }
  }
  
  # arrange for a start/stop Button or similar to invoke this callback
  sub start_toggle
  {
  	$running = $running ? 0 : 1;
  }

As every call to C<taxis> involves iterating over the entire population, when 
that population is small, the iterations occur more quickly than when the 
population is large. This event loop ensures that small populations do not
whizz around madly (as would be the case if we used a simple C<while> loop), 
whilst ensuring that large populations do not cause the script to hang in deep
recursion (as would be the case if we used a timed C<repeat> callback and a
default C<MainLoop()>).

=head1 SEE ALSO

L<Tk::Taxis::Critter>

=head1 AUTHOR

Steve Cook, E<lt>steve@steve.gb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Steve Cook

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
