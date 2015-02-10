#!/usr/bin/env perl
# Copyright 2010-2012 Ricky Thomson - <punkalert@gmail.com>
#
# RuneMage is free software; you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published 
# by the Free Software Foundation; either version 2 of the License, 
# or (at your option) any later version.
#
# RuneMage is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with RuneMage; if not, write to the Free Software Foundation, 
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

use strict;
use warnings;
use utf8;

#
# `perldoc Gtk2::Webkit`
#

use threads;
use FindBin qw($Bin); 

use Glib qw{ TRUE FALSE };
use Gtk2 '-init';

use LWP::Simple qw($ua getstore get);
$ua->timeout(4);









my $version = "0.8.0"; 


my $home = $ENV{ HOME } . "/.runemage/";
my $icon_store	  = $home . "skill_icons/";
my $gladexml	= $Bin . "..//data/ui/launcher.xml";


my $icon_location = "http://www.runescape.com/img/hiscore/compare/skills/";


my @icons = (		"xp_attack_total.png", 	"xp_defence_total.png",
			"xp_strength_total.png", 	"xp_constit_total.png",
			"xp_ranged_total.png", 	"xp_prayer_total.png",
			"xp_magic_total.png", 	"xp_cooking_total.png",
			"xp_woodcutting_total.png", 	"xp_fletching_total.png",
			"xp_fishing_total.png", 	"xp_firemaking_total.png",
			"xp_crafting_total.png", 	"xp_smithing_total.png", 
			"xp_mining_total.png", 	"xp_herblore_total.png",
			"xp_agility_total.png", 	"xp_thieving_total.png",
			"xp_slayer_total.png", 	"xp_farming_total.png",
			"xp_runecraft_total.png", 	"xp_hunter_total.png",
			"xp_construct_total.png", "xp_summoning_total.png", 
			"xp_dungeon_total.png", 
);


my ( $builder, $dialog,$progress_bar );
use subs qw{ main on_window_destroy };


my $i = 0;


&main;





sub main {
	

	$builder = Gtk2::Builder->new();
	 
	# load converted glade XML file
	$builder->add_from_file( $gladexml );

	$progress_bar = $builder->get_object('progress');
	$progress_bar->pulse;
	Glib::Timeout->add(100, \&update_progress_bar, $progress_bar);
	
	# get top level object as named in glade XML
	$dialog = $builder->get_object( 'dialog1' );
	
	$builder->get_object( 'logo' )->set_from_file( "../data/swords.png" );
	$builder->connect_signals( undef );
	
		
	$dialog->show_all();

	
	
	Gtk2->main();

}


sub gtk_main_quit {
	
	# clean shutdown
	$dialog->destroy;

	Gtk2->main_quit();

}





sub on_btnCancel_clicked {	
	gtk_main_quit();
}







sub on_btnOK_clicked {	
	if ( ! -e $home )	{ mkdir $home or die $!; };
	if ( ! -e $icon_store ) { mkdir $icon_store or die $!; }

	if ( -e $gladexml ) {  print "** DATA - $gladexml\n"; } else { die "** '$gladexml' $!"; }


	my @icon_threads;

	foreach ( @icons ) {
		if ( ! -e "$icon_store$_" ) {
				
	
			push @icon_threads, threads->new( 
				sub { 
					getstore( "$icon_location$_" , "$icon_store$_" );
						
					print "** HTTP - Fetching '$_'\n";
	
				}
		);	
		Gtk2->main_iteration while Gtk2->events_pending;
	} else {	
			print "** DATA - Found '$icon_store$_'\n";
	}	
	}
	

	
	# rejoin threads 
	foreach (@icon_threads) {
		$_->join();
		$progress_bar->set_fraction( $i / @icons );
	}	
	
	@icon_threads = ();

	if ( ! -e "$icon_store/skill_total.png" ) {
		getstore( "http://www.runescape.com/img/clan/stats/stats/skill_total.png", $icon_store."/skill_total.png");
	}


}

###EOF###



