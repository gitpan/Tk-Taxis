#!/usr/bin/perl 

# woodlice.pl v1.04

use strict;
use warnings;

if ( $ARGV[0] && $ARGV[0] =~ /^-{1,2}(h|help|\?)$/i )
{
	system ( "perldoc", $0 ) and die "For usage, use perldoc $0\n";
	exit( 0 );
}

use Tk qw( DoOneEvent DONT_WAIT ALL_EVENTS );
use Tk::Taxis;

########################## defaults and bindings  ##############################

use constant VERT       => 400;
use constant HORIZ      => 800;
use constant POPULATION => 10;
use constant PREFERENCE => 100;
use constant CRITTERS   => "woodlice";
use constant COLOUR     => '#8445e3'; # dddddd is quite nice too
my $running    = 0;
my $counter    = 0;
my $paused     = 0;
my $first_time = 0;
my $preference = PREFERENCE;
my $population = POPULATION;
my $critters   = CRITTERS;
my $colour     = COLOUR;
my $vert       = VERT;
my $horiz      = HORIZ;

use Getopt::Long;
GetOptions
(
	"colour=s"   => \$colour,
	"vert=i"     => \$vert,
	"horiz=i"    => \$horiz,
	"image=s"    => \$critters,
);
$colour = "#$colour" unless $colour =~ /^#/;

use File::Temp 'tempfile';
use File::Spec;
my $tmpdir = File::Spec->tmpdir();
my $logfile = tempfile
( 
	"woodliceXXXX", 
	DIR    => $tmpdir, 
	SUFFIX => '.tmp', 
	UNLINK => 1, 
);
my $log_number = 1;

my $mw = new MainWindow( -title => "Woodlouse simulation" );
$mw->Tk::bind( '<Alt-F4>'     => [ sub { exit 0 } ] );
$mw->Tk::bind( '<Control-F4>' => [ sub { exit 0 } ] );
$mw->Tk::bind( '<Control-s>'  => \&start_toggle );
$mw->Tk::bind( '<Control-p>'  => \&pause_toggle );
$mw->Tk::bind( '<F1>'         => \&help );
$mw->Tk::bind( '<Control-h>'  => \&help );
$mw->Tk::bind( '<Control-o>'  => \&options );
$mw->Tk::bind( '<Control-l>'  => \&save );
$mw->setPalette( $colour );

################################### menu bar ###################################

	my $menu = $mw->Menu();
		my $file = $menu->cascade
		(
			-label     => 'File',
			-underline => '0',
			-tearoff   => '0'
		);
			$file->command
			(
				-label     => 'Save log file',
				-font      => 'sserife 8',
				-underline => 0,
				-command   => \&save,
			);
			$file->command
			(
				-label     => 'Exit',
				-font      => 'sserife 8',
				-underline => 1,
				-command   => [ sub { exit(0) } ],
			);
		my $simulate = $menu->cascade
		(
			-label     => 'Simulate',
			-underline => '0',
			-tearoff   => '0'
		);
			my $start_menu = $simulate->command
			(
				-label     => 'Start',
				-font      => 'sserife 8',
				-underline => '0',
				-command   => \&start_toggle,
			);
			my $pause_menu = $simulate->command
			(
				-label     => 'Pause',
				-font      => 'sserife 8',
				-underline => '0',
				-state     => 'disabled',
				-command   => \&pause_toggle,
			);
			my $option_menu = $simulate->command
			(
				-label     => 'Options',
				-font      => 'sserife 8',
				-underline => '0',
				-command   => \&options,
			);
		my $help = $menu->cascade
		(
			-label     => 'Help',
			-underline => '0',
			-tearoff   => '0'
		);
			$help->command
			(
				-label     => 'Help',
				-font      => 'sserife 8',
				-underline => '0',
				-command   => \&help,
			);
			$help->command
			(
				-label     => 'About',
				-font      => 'sserife 8',
				-underline => '0',
				-command   => \&about,
			);
		$mw->configure( -menu => $menu );

################################## simulation ##################################
	
	my $main = $mw->Frame( -background => 'gray' )->pack();
		my $taxis_frame = $main->Frame
		(
			-relief       => 'groove', 
			-borderwidth  => 2,
			-background => 'gray',
		);
		$taxis_frame->pack
		(
			-padx   => 10,
			-pady   => 5,
		);
		my $taxis = $taxis_frame->Taxis
		( 
			-width      => $horiz,
			-height     => $vert,
			-preference => $preference,
			-population => $population,
			-images     => $critters,
		)
		->pack();
		my $frame = $main->Frame
		(
			-relief       => 'groove', 
			-borderwidth  => 2,
			-background => 'gray',
		);
		$frame->pack
		(
			-expand => 1, 
			-padx   => 10,
			-pady   => 5,
			-fill   => 'x',
		 );
			my $left_count = $frame->Label
			( 
				-relief      => 'groove',
				-font        => "sserif 14",
				-borderwidth => 2,
				-width       => 10,
				-text        => "Right: 0",
			)
			->grid
			(
				-column   => 1, 
				-row      => 0, 
				-padx     => 20, 
				-pady     => 5,
				-sticky   => 'ns',
			);
			my $start_button = $frame->Button
			( 
				-text     => "Start",
				-command  => \&start_toggle,
				-font     => "sserif 14",
				-width    => 10,
			)
			->grid
			(
				-column   => 2, 
				-row      => 0,
				-padx     => 20,
				-pady     => 5,
			);
			$start_button->focus();
			my $pause_button = $frame->Button
			( 
				-text     => "Pause",
				-command  => \&pause_toggle,
				-font     => "sserif 14",
				-state    => 'disabled',
				-width    => 10,
			)
			->grid
			(
				-column   => 3, 
				-row      => 0, 
				-padx     => 20, 
				-pady     => 5,
			);
			my $timer = $frame->Label
			( 
				-text        => "Time (s): 0",
				-relief      => 'groove',
				-font        => "sserif 14",
				-borderwidth => 2,
				-width       => 10,
			)
			->grid
			(
				-column   => 4, 
				-row      => 0, 
				-padx     => 20, 
				-pady     => 5, 
				-sticky   => 'ns',
			);
			my $right_count = $frame->Label
			( 
				-relief      => 'groove',
				-font        => "sserif 14",
				-borderwidth => 2,
				-width       => 10,
				-text        => "Right: 0",
			)
			->grid
			(
				-column   => 5, 
				-row      => 0, 
				-padx     => 20, 
				-pady     => 5,
				-sticky   => 'ns',
			);
	
################################## event loop ##################################

$mw->repeat
(
	1000,
	[ 
		sub 
		{ 
			if ( $running )
			{
				my ( $left, $right ) = $taxis->cget( -population );
				print $logfile "$counter\t$left\t$right\n";
				$counter++;
			}
		}
	] 
);

while ( 1 )
{
	DoOneEvent( $running ? DONT_WAIT : ALL_EVENTS );
	$taxis->taxis() if $running && not $paused;
	$timer->configure( -text => sprintf "Time (s): %u", $counter );
	my ( $left, $right ) = $taxis->cget( -population );
	$left_count->configure(  -text => "Left: $left"   );
	$right_count->configure( -text => "Right: $right" );
}

################################### toggles ####################################

sub start_toggle
{
	if ( $running )
	{
		$running = 0;
		$paused  = 0;
		$start_button->configure
		(
			-text  => "Start",
		);
		$start_menu->configure
		(
			-label => "Start",
		);
		$pause_button->configure
		(
			-text  => "Pause", 
			-state => 'disabled',
		);
		$pause_menu->configure
		(
			-label => "Pause", 
			-state => 'disabled',
		);
		$option_menu->configure
		( 
			-state => 'normal',
		);

	}
	else
	{	
		$counter = 0;
		$paused  = 0;
		$running = 1;
		new_log();
		if ( $first_time++ )
		{
			$taxis->configure( -population => $population );
			$taxis->configure( -preference => $preference );
		}
		$start_button->configure
		(
			-text  => "Stop",
		);
		$start_menu->configure
		(
			-label => "Stop",
		);
		$pause_button->configure
		(
			-text  => "Pause", 
			-state => 'normal',
		);
		$pause_menu->configure
		( 
			-label => "Pause", 
			-state => 'normal',
		);
		$option_menu->configure
		( 
			-state => 'disabled',
		);
	}
}

sub pause_toggle
{
	if ( $paused )
	{
		$paused  = 0;
		$pause_button->configure
		(
			-text  => "Pause",
		);
		$pause_menu->configure
		(
			-label => "Pause"
		);	
	}
	else
	{
		$paused  = 1;
		$pause_button->configure
		(
			-text  => "Unpause",
		);
		$pause_menu->configure
		(
			-label => "Unpause", 
		);	
	}
}

#################################### popups ####################################

sub help
{
	my $help_text = << "THIS";
This software simulates the movement of organisms which work out where to go by 
measuring the current value of e.g. darkness, and comparing it to the darkness 
they experienced just a moment ago. If they find the darkness has got darker,
they carry on running in the same direction, otherwise, they take a random 
tumble to a new direction. This makes them perform a biased random walk towards
the dark. The author doesn't know whether woodlice do this, but they are more 
attractive than bacteria, which certainly do. 



To start a new simulation, press the 'Start' 
button. To pause it temporarily, press the 'Pause' 
button.



When the simulation is stopped, options can also be set using 'Options' on the 
'Simulate' menu. The population can be varied from 1 to 50 using the slider, and
the critters' preference can be varied from 0 to +/-100. The preference tells 
the woodlice how much they want to go to the dark side: a preference of 0 
indicates no preference at all, and negative preferences will make the woodlice 
veer away from the dark!



A log is kept of the current option settings and the number of critters on the 
left and right sides, every second. This can be saved using 'Save log file' on 
'File' toolbar when the simulation is stopped.



Keyboard shortcuts:

\tF1\tHelp

\tCtrl-S\tStart/stop

\tCtrl-P\tPause/unpause

\tCtrl-O\tOptions (when stopped)

\tCtrl-L\tSave log file (when stopped)

\tAlt-F4\tExit
THIS
	my @help_text = split /\n\n/, $help_text;
	s/\n//g for @help_text;
	$help_text = join "\n", @help_text;
	my $help = $mw->Toplevel
	(
		-background   => 'gray',
		-width => 12,
	);
	$help->title( "Help" );
	my $frame = $help->Frame
	(
		-borderwidth  => 2,
		-relief       => 'groove',
		-background   => 'gray',
	);
	$frame->grid
	(
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		-padx         => 5,
		-pady         => 5,
		-sticky       => 'ew',
	);
	my $text = $frame->Label
	(
		-font       => 'sserif 12',
		-text       => $help_text,
		-wraplength => 600,
		-justify    => 'left',
		-background => 'gray',
	);
	$text->grid
	(
		-column       => 1,
		-row          => 1, 
		-padx         => 20, 
		-pady         => 5,
		-sticky       => 'ew', 
	);
	my $ok = $frame->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [ sub { $help->destroy() } ],
		-width        => 10,
	);
	$ok->grid
	(
		-column       => 1,
		-row          => 2, 
		-padx         => 20, 
		-pady         => 5, 
	);
    $help->Tk::bind( '<Alt-F4>' => [ sub { $help->destroy() } ] );
    $help->Tk::bind( '<Escape>' => [ sub { $help->destroy() } ] );
	$help->raise();
	$ok->focus();
}

sub dialog
{
	my ( $dialog_text, $title ) = @_;
	my $dialog = $mw->Toplevel( -width => 1000 );
	$dialog->title( $title || "Dialog" );
	my $frame = $dialog->Frame
	(
		-borderwidth  => 2,
		-relief       => 'groove',
		-background   => 'gray',
	);
	$frame->grid
	(
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		-padx         => 5,
		-pady         => 5,
	);
	my $text = $frame->Label
	(
		-width      => 50,
		-font       => 'sserif 12',
		-text       => $dialog_text,
		-wraplength => 400,
		-justify    => 'left',
		-background => 'gray',
	);
	$text->grid
	(
		-column       => 1,
		-row          => 1, 
		-padx         => 20, 
		-pady         => 5,
		-sticky       => 'ew', 
	);
	my $ok = $frame->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [ sub { $dialog->destroy() } ],
		-width        => 10,
	);
	$ok->grid
	(
		-column       => 1,
		-row          => 2, 
		-padx         => 20, 
		-pady         => 5, 
	);
    $dialog->Tk::bind( '<Alt-F4>' => [ sub { $dialog->destroy() } ] );
    $dialog->Tk::bind( '<Escape>' => [ sub { $dialog->destroy() } ] );
	$dialog->raise();
	$ok->focus();
}

sub about
{
	my $about_text = << "THIS";
Woodlouse Simulator (C) Dr. Cook 2003

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
THIS
	dialog( $about_text, "About" );
}

sub options
{
	return if $running;
	my $option_box = $mw->Toplevel
	(
		-width      => 1000, 
		-background => 'gray',
	);
	$option_box->title( "Options" );
	my $preference_frame = $option_box->Frame
	(
		-borderwidth  => 2,
		-relief       => 'groove',
		-background   => 'gray',
	);
	my $preference_scale = $preference_frame->Scale
	(
		-label        => "Preference",
		-font         => "sserif 14",
		-orient       => 'horizontal', 
		-from         => -100, 
		-to           => 100, 
		-length       => 300, 
		-tickinterval => 50,
		-background   => 'gray',
	);
	$preference_scale->set( $preference );
	$preference_scale->pack();
	$preference_frame->grid
	(
		-column       => 1, 
		-row          => 1, 
		-columnspan   => 2, 
		-padx         => 5,
		-pady         => 5,
	);
	
	my $population_frame = $option_box->Frame
	(
		-borderwidth  => 2,
		-relief       => 'groove',
		-background   => 'gray',
	);
	my $population_scale = $population_frame->Scale
	(
		-label        => "Population",
		-font         => "sserif 14",
		-orient       => 'horizontal', 
		-from         => 0, 
		-to           => 50, 
		-length       => 300, 
		-tickinterval => 10,
		-background   => 'gray',
	);
	$population_scale->set( $population );
	$population_scale->pack();
	$population_frame->grid
	(	
		-column       => 1, 
		-row          => 2, 
		-columnspan   => 2, 
		-padx         => 5, 
		-pady         => 5,
	);
	
	my $ok = $option_box->Button
	( 
		-text         => "OK", 
		-font         => "sserif 14",
		-command      => [
						sub
						{
							$preference = $preference_scale->get();
							$population = $population_scale->get();
							$first_time = 0;
							$taxis->configure( -population => $population ); 
							$taxis->configure( -preference => $preference ); 
							$option_box->destroy();
						}
					],
		-width        => 10,
	)->grid(
		-column       => 1,
		-row          => 3, 
		-padx         => 20, 
		-pady         => 10, 
		-sticky       => 'ew', 
	);
	my $cancel = $option_box->Button
	( 
		-text         => "Cancel", 
		-font         => "sserif 14",
		-command      => [
						sub
						{
							$option_box->destroy();
						}
					],
		-width        => 10,
					
	)->grid(
		-column       => 2, 
		-row          => 3, 
		-padx         => 20, 
		-pady         => 10,
	);
	$option_box->raise();
	$ok->focus();
	$option_box->Tk::bind( '<Alt-F4>' => [ sub { $option_box->destroy() } ] );
	$option_box->Tk::bind( '<Escape>' => [ sub { $option_box->destroy() } ] );
}

################################### logging ####################################

sub save
{	
	my $default = "woodlice$log_number";
	my $save_window = $mw->getSaveFile
	(
		-filetypes        => [ [ 'Log files' => '.log' ] ],
		-initialfile      => $default,
		-defaultextension => '.log',
	);
	if ( defined $save_window )
	{
		local *LOG;
		unless ( open LOG, ">", $save_window )
		{
			dialog( "Can't save log to file $save_window: $!", "Error" );
			return;
		}
		seek $logfile, 0, 0;
		print LOG $_ while <$logfile>;
		close LOG;
		$log_number++;
	}
}

sub new_log
{
	truncate $logfile, 0;
	seek $logfile, 0, 0;
	print $logfile <<"THIS";
Woodlouse simulator log file
Population\t$population
Preference\t$preference
Time\tLeft\tRight
THIS
}

__END__

=head1 NAME

woodlice.pl - Perl script for running woodlouse simulator

=head1 SYNOPSIS

  perl woodlice.pl [-colour #eeeeee -horiz 400 -vert 400 -image bacteria]

=head1 ABSTRACT

Woodlouse simulator

=head1 DESCRIPTION

Invokes woodloue simulation demo using C<Tk::Taxis> and C<Tk::Taxis::Critter>.
Press F1 whilst executing for help. The C<colour>, C<horiz>(ontal) C<vert>(ical)
and critter C<image> can be configured from the command line with the 
appropriate switches.

=head1 SEE ALSO

L<perl>

C<Tk::Taxis>

C<Tk::Taxis::Critter>

=head1 AUTHOR

Steve Cook, E<lt>steve@steve.gb.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Steve Cook

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

}