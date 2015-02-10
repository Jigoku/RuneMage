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


##############################
# Perl module dependencies:
#
#   Gtk2
#   Gtk2::WebKit
#   Gtk2::ImageView
#   Gtk2::TrayIcon
#   XML::Simple
#   LWP::Simple
#
##############################

use threads;
use FindBin qw($Bin); 

use Glib qw{ TRUE FALSE };
use Gtk2 '-init';

use QtWebKit4;
#use Gtk2::WebKit;

use Gtk2::ImageView;
use Gtk2::TrayIcon;

use XML::Simple;
use LWP::Simple qw($ua getstore get);

$ua->timeout(4);



my (
	$verbose,	
	$version,	# Version
	$gladexml,	# Path to the Glade UI (xml format)
	$splash,	# Path to the splash page.
	$imageviewer,
	# Configurable 
	
	$conf_path,		# Path to local storage		(default: ~/.runemage/)
	$conf_path_icons,	# Path to cached icons		(default: ~/.runemage/icons)
	$conf_path_itemdb,	# Path to fetched itemdb images (default: ~/.runemage/itemdb)
	$url_game,		# URL loaded when "File> Play Runescape" is clicked.
	$url_classic,		# URL loaded when "File> Play Runescape Classic" is clicked.
	$url_hiscore,		# The base URL of the "lite" api for the runescape hiscores.
	$url_icons,		# The base URL for the skill icons on the hiscores page.
	$url_alog,		# The base URL for the alog rss feed
	$gebase,		# Deprecated.

	$mapzoom,		# Level of zoom for the "Tools>World Map". (Default: 1.00)

	
	$builder,
	$window,
	$webkit,
);



####################### configuration ######################
$verbose		= 0;
$version		= "0.7.9 (dev)"; 

$conf_path		= $ENV{ HOME } . "/.runemage/";
$conf_path_icons	= $conf_path . "icons/";
$conf_path_itemdb	= $conf_path . "itemdb/";

#$url_game		= "http://runescape.com/";
$url_game		= "http://www.java.com/en/download/installed.jsp?detect=jre&try=1";
$url_classic		= "http://runescape.com/classicapplet/playclassic.ws";
$url_hiscore		= "http://hiscore.runescape.com/index_lite.ws?player=";
$url_icons		= "http://www.runescape.com/img/hiscore/compare/skills/";
$url_alog		= "http://services.runescape.com/m=adventurers-log/rssfeed?searchName=";
$gebase			= "http://services.runescape.com/m=itemdb_rs";
$splash			= $Bin . "/data/ui/splash.html";
$gladexml		= $Bin . "/data/ui/runemage.xml";

$mapzoom		= 1.00;


my @icons = (		"xp_attack_total.png", 	 
			"xp_defence_total.png",
			"xp_strength_total.png", 	
			"xp_constit_total.png",
			"xp_ranged_total.png", 	
			"xp_prayer_total.png",
			"xp_magic_total.png", 	
			"xp_cooking_total.png",
			"xp_woodcutting_total.png", 	
			"xp_fletching_total.png",
			"xp_fishing_total.png", 	
			"xp_firemaking_total.png",
			"xp_crafting_total.png", 	
			"xp_smithing_total.png", 
			"xp_mining_total.png", 	
			"xp_herblore_total.png",
			"xp_agility_total.png", 	
			"xp_thieving_total.png",
			"xp_slayer_total.png", 	
			"xp_farming_total.png",
			"xp_runecraft_total.png", 	
			"xp_hunter_total.png",
			"xp_construct_total.png", 
			"xp_summoning_total.png", 
			"xp_dungeon_total.png",
			
			"dueltournament.png", 
			"bountyhunters.png",
			"bountyhunterrogues.png",
			"fistofguthix.png",
			"mobilisingarmies.png",
			"baattackers.png",
			"badefenders.png",
			"bacollectors.png",
			"bahealers.png",
			"castlewarsgames.png",
			"conquest.png",
			"dominiontower.png",
			"thecrucible.png",
			"ggathletics.png", 
			"ggresourcerace.png",
			
);
############################################################




use subs qw{ main on_window_destroy };



###
### startup_checks();
###
### Make sure we have everything setup correctly.
###
###
sub startup_checks 
{

	# No excuse...
	if ( $< == 0 ) 
	{ 
		die "I WILL NOT RUN AS ROOT, STUPID!\n";
	}
	
	
	# Check arguments passed to the client at runtime
	if ( $#ARGV >= 0 ) {
		if ( $ARGV[0] eq "--version" ) {
			# display licence / version info
			license();
			exit 0;
		}
	
		if ( $ARGV[0] eq "--debug" ) {
			# switch on verbose output
			$verbose = 1;
	
		}
	}
	
	if ( ! $verbose == 0 ) {
		print "RuneMage v$version - Copyright 2010-2012; Ricky T <punkalert\@gmail.com>\n\n";
	
	}
	
	# Make needed directories for config / cache stores
	if ( ! -e $conf_path )	{ mkdir $conf_path or die $!; };
	if ( ! -e $conf_path_itemdb )	{ mkdir $conf_path_itemdb or die $!; }
	if ( ! -e $conf_path_icons ) { mkdir $conf_path_icons or die $!; }

	# Check for a splash page. (doesnt matter if it's missing, but why would it go missing?)
	if ( -e $splash ) { 
		if ( ! $verbose == 0 ) { print "** DATA - $splash\n"; } 
	} else { 
		warn "** '$splash' $!"; 
	}

	# Make sure gladexml (interface) file exists or die. (we need this!)
	
	if ( -e $gladexml ) {  
		if ( ! $verbose == 0 ) { print "** DATA - $gladexml\n"; }
	} else {	
		die "** '$gladexml' $!"; 
	}

}



###
### fetch_icons();
###
### Fetches the runescape icons from the hiscore section of the official
### website. Reason for this, is the license (unknown), but obviously not 
### CC/GPL so cannot be redistributed with the client.
###
###
sub fetch_icons
{
	my @icon_threads;
	
	foreach ( @icons ) {
		if ( ! -e "$conf_path_icons$_" ) {
			push @icon_threads, threads->new( 
				sub { 
					getstore( "$url_icons$_" , "$conf_path_icons$_" );	
					if ( ! $verbose == 0 ) { print "** HTTP - Fetching '$_'\n"; }
				}
			);
		} else {
			if ( ! $verbose == 0 ) { print "** DATA - Found '$conf_path_icons$_'\n"; }
		}	
	}


	# rejoin threads 
	foreach (@icon_threads) {
		$_->join();
	}	

	@icon_threads = ();

	if ( ! -e "$conf_path_icons/skill_total.png" ) {
		getstore( "http://www.runescape.com/img/clan/stats/stats/skill_total.png", $conf_path_icons."skill_total.png");
		if ( ! $verbose == 0 ) { print "** DATA - Found '$conf_path_icons/skill_total.png'\n"; }
	}

}



###
### create_tray_icon();
###
### Add RuneMage to the tray area of the desktop environment. 
### Can be used to hide/show the window, good for emergencies!
###
###
sub create_tray_icon 
{


	my $icon = Gtk2::Image->new_from_pixbuf( 
		Gtk2::Gdk::Pixbuf->new_from_file("data/ui/logo-tray.png")
	);
	
	my $eventbox = Gtk2::EventBox->new;
		$eventbox->add( $icon );
		
	my $trayicon = Gtk2::TrayIcon->new( 'RuneMage' );
	$trayicon->add( $eventbox );
	
	my $tooltip = Gtk2::Tooltips->new;
	$tooltip->set_tip( $trayicon, "RuneMage " . $version );
	
	$eventbox->signal_connect( 'button_press_event', 
		sub { 
			if ( $_[ 1 ]->button == 1 ) {
				$window->hide(); #left click hides client (from taskbar + desktop)
			} 
			elsif ( $_[ 1 ]->button == 3 ) {
				$window->show(); #right click restores client
			}
		   }
		
	);
	
	$trayicon->show_all;
}




sub on_combobox_changed {
	my $combobox = $builder->get_object( 'combobox' );
	
	my $stats	= $builder->get_object( 'port_stats' );
	my $minigames	= $builder->get_object( 'port_minigames' );

	if ($combobox->get_active == 0) { $stats->show; $minigames->hide;}
	if ($combobox->get_active == 1) { $stats->hide; $minigames->show; }
}




&startup_checks; 
&fetch_icons;
&create_tray_icon;
&main;









################################################################################

sub main {
	
	
	
	
	$builder = Gtk2::Builder->new();

	# load converted glade XML file
	$builder->add_from_file( $gladexml );

	# get top level object as named in glade XML
	$window = $builder->get_object( 'main_window' );

	# resize the window
	$window->set_default_size(1200, 750);
		

	# create a browser widget
#	$webkit =  QtWebKit4->new;

#	my $websettings = Gtk2::WebKit::WebSettings->new;
	
#	my $webkitver = Gtk2::WebKit->major_version . "." . 
#			Gtk2::WebKit->micro_version . "." . 
#			Gtk2::WebKit->minor_version;
#	$websettings->set_property('user-agent', "RuneMage/0.8.0 (X11; Linux x86_64) WebKit/" . $webkitver);
#	$websettings->set_property('enable-java-applet', 1);
#	$websettings->set_property('enable-plugins', 1);
#		
#	$webkit->set_settings($websettings);


	# load offline welcome/splash page
#	destination_url( "file://" . $splash );

	# define object that should hold browser widget
	our $url_gamewindow = $builder->get_object( 'scrolled_window' );

	# pack webkit widget
#	$url_gamewindow->add( $webkit );
	

	# we need to manually set the icons
	foreach ( @icons ) { $builder->get_object( $_ )->set_from_file( "$conf_path_icons$_" ); }

	# set misc icons
	$builder->get_object( 'hiscore_icon' )->set_from_file( $conf_path_icons."skill_total.png" );
	$builder->get_object( 'itemdb_icon' )->set_from_file( $conf_path_icons."coins.png" );
	$builder->get_object( 'log_icon' )->set_from_file( $conf_path_icons."log.png" );
	#$builder->get_object( 'quest_icon' )->set_from_file( $conf_path_icons."quest.png" );
	


	# main_window
	$builder->connect_signals( undef );
	$window->show_all();

	Gtk2->main();

}


sub gtk_main_quit {
	$window->destroy;
	Gtk2->main_quit();
}




# add commas to string of numbers, 
#1234567 returns 1,234,567
sub commify {
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

# trims whitespace, 
#leaving single space intact
sub trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}



# handles the webpage to be loaded
#sub destination_url { $webkit ->load_uri( @_ ) }


# fetch a text entry contents as string
sub grab_text_entry{ $builder->get_object( @_ )->get_text; }

# set a bold text entry with markup
sub set_text_entry { our ( $label, $text ) = @_; $builder->get_object( $label )->set_markup("<b>" . $text . "</b>") ; }







sub on_btnSearch_clicked {

	Gtk2->main_iteration while (Gtk2->events_pending);
	$builder->get_object( 'combobox' )->set_active(0);
	
	# get the text input string of "search_entry"
	our $rsn = grab_text_entry('hiscore_search');
		

	# fetch data from hiscore of text input
	our $data = get( $url_hiscore . $rsn ) or warn $!;


	# if user doesn't exist / not ranked at all (no data is returned, 404)
	# in that case we can quit the whole sub after showing an error message
		if ( !$data ) {

			# This should be displayed as an alert box (probably annoying though)

			&clear_hiscores();
			
			return;
		}

	# otherwise continue, replace newline characters for commas
		$data =~ s/[\n]/,/g; 


	# split string into array at each comma
		our @s = ( split(/,/, $data ) );


	# pass appropriate values to labels and set them
	# 1st param 's' = skill type
	
			#TYPE  #LABEL TO USE#	#SKILL#				#LVL#	#RANK#	 #EXP#
		set_skill('s', "lbl_attack"	    , "Attack" 		,	$s[4]  , $s[3]  ,$s[5]	);
		set_skill('s', "lbl_defence"     , "Defence"		,	$s[7]  , $s[6]  ,$s[8]	);
		set_skill('s', "lbl_strength"    , "Strength"	,		$s[10] , $s[9]  ,$s[11]	);
		set_skill('s', "lbl_hitpoints"   , "Constitution"	,	$s[13] , $s[12] ,$s[14]	);
		set_skill('s', "lbl_ranged"      , "Ranged"		,	$s[16] , $s[15] ,$s[17]	);
		set_skill('s', "lbl_prayer"      , "Prayer"		,	$s[19] , $s[18] ,$s[20]	);
		set_skill('s', "lbl_magic"       , "Magic"		,	$s[22] , $s[21] ,$s[23]	);
		set_skill('s', "lbl_cooking"     , "Cooking"		,	$s[25] , $s[24] ,$s[26]	);
		set_skill('s', "lbl_wc"          , "Woodcutting"	,	$s[28] , $s[27] ,$s[29]	);
		set_skill('s', "lbl_fletch"      , "Fletching"	,		$s[31] , $s[30] ,$s[32]	);
		set_skill('s', "lbl_fishing"     , "Fishing"		,	$s[34] , $s[33] ,$s[35]	);
		set_skill('s', "lbl_fm"          , "Firemaking"	,		$s[37] , $s[36] ,$s[38] );
		set_skill('s', "lbl_craft"       , "Crafting"	,		$s[40] , $s[39] ,$s[41]	);
		set_skill('s', "lbl_smithing"    , "Smithing"	,		$s[43] , $s[42] ,$s[44]	);
		set_skill('s', "lbl_mining"      , "Mining"		,	$s[46] , $s[45] ,$s[47]	);
		set_skill('s', "lbl_herblore"    , "Herblore"	,		$s[49] , $s[48] ,$s[50]	);
		set_skill('s', "lbl_agility"     , "Agility"		,	$s[52] , $s[51] ,$s[53]	);
		set_skill('s', "lbl_thieveing"   , "Thieving"	,		$s[55] , $s[54] ,$s[56] );
		set_skill('s', "lbl_slayer"      , "Slayer"		,	$s[58] , $s[57] ,$s[59]	);
		set_skill('s', "lbl_farm"        , "Farming"		,	$s[61] , $s[60] ,$s[62]	);
		set_skill('s', "lbl_rc"          , "Runecrafting"	,	$s[64] , $s[63] ,$s[65]	);
		set_skill('s', "lbl_hunter"      , "Hunter"		,	$s[67] , $s[66] ,$s[68]	);	
		set_skill('s', "lbl_construction", "Construction"	,	$s[70] , $s[69] ,$s[71] );
		set_skill('s', "lbl_summon"      , "Summoning"	,		$s[73] , $s[72] ,$s[74]	);
		set_skill('s', "lbl_dungeon"     , "Dungeoneering"	,	$s[76] , $s[75] ,$s[77]	);
		
	# 1st param 't' = total type
		set_skill('t', "lbl_rank"	 , "Overall Rank"	,	$s[0], 0,0 );
		set_skill('t', "lbl_total"       , "Total Level"	,	$s[1], 0,0 );
		set_skill('t', "lbl_xp"          , "Total XP"	,		$s[2], 0,0 );

	# 1st param 'm' = minigame type
		
		set_skill('m', "lbl_duel_score","Duel Tournament Score",$s[79], 0,0 ); 
		set_skill('m', "lbl_duel_rank","Duel Tournament Rank",$s[78], 0,0);
		set_skill('m', "lbl_bh_score",	"Bounty Hunter Score",$s[81], 0,0);
		set_skill('m', "lbl_bh_rank",	"Bounty Hunter Rank",$s[80], 0,0);
		set_skill('m', "lbl_bhr_score",	"Bounty Hunter Rogues Score",	$s[83], 0,0);
		set_skill('m', "lbl_bhr_rank",	"Bounty Hunter Rogues Rank",	 $s[82], 0,0);
		set_skill('m', "lbl_fog_score",	"Fist Of Guthix Score",$s[85],0,0 );
		set_skill('m', "lbl_fog_rank",	"Fist Of Guthix Rank", $s[84] ,0,0);
}


sub set_skill {

	# pass name of label to display value parsed from hiscores lookup
	our ( $type, $label, $skill,  $lvl, $rank, $exp ) = @_;

	$rank = commify( "$rank" );
	$exp  = commify( "$exp"  );
	
	
	
	# clean up output for unranked skills
	# -1 is used for unranked in returned data, we display 0 instead. 
	if ( $lvl == -1 ) { 
		$rank = "n/a";
		$exp  = "n/a";
		$lvl  = "-";
	} else {
		$lvl  = commify( "$lvl"	);

	}


	
	if ( $type eq 's' ) {
		# update tooltip data for skill values
		our $tooltip = "<b><u>$skill</u></b>\n<b>Rank:</b> $rank\n<b>Exp:</b> $exp";
		$builder->get_object( $label )->set_tooltip_markup( $tooltip );
	} 
	
	if ( $type eq 'm' ) {
		# update tooltip data for minigame values
		our $tooltip = "<b>$skill</b>";
		$builder->get_object( $label )->set_tooltip_markup( $tooltip );
	} 
	

	set_text_entry( $label, $lvl );

	
	
	


}

sub clear_hiscores {
		# this could be done a different way.....
		
		$builder->get_object( 'hiscore_search')->set_text( "Error!" 	);
				
		set_text_entry("lbl_attack"	 , "-" 	);
		set_text_entry("lbl_defence"     , "-"	);
		set_text_entry("lbl_strength"    , "-"	);
		set_text_entry("lbl_hitpoints"   , "-"	);
		set_text_entry("lbl_ranged"      , "-"	);
		set_text_entry("lbl_prayer"      , "-"	);
		set_text_entry("lbl_magic"       , "-"	);
		set_text_entry("lbl_cooking"     , "-"	);
		set_text_entry("lbl_wc"          , "-"	);
		set_text_entry("lbl_fletch"      , "-"	);
		set_text_entry("lbl_fishing"     , "-"	);
		set_text_entry("lbl_fm"          , "-"	);
		set_text_entry("lbl_craft"       , "-"	);
		set_text_entry("lbl_smithing"    , "-"	);
		set_text_entry("lbl_mining"      , "-"	);
		set_text_entry("lbl_herblore"    , "-"	);
		set_text_entry("lbl_agility"     , "-"	);
		set_text_entry("lbl_thieveing"   , "-"  );
		set_text_entry("lbl_slayer"      , "-"	);
		set_text_entry("lbl_farm"        , "-"	);
		set_text_entry("lbl_rc"          , "-"	);
		set_text_entry("lbl_hunter"      , "-"	);	
		set_text_entry("lbl_construction", "-"  );
		set_text_entry("lbl_summon"      , "-"	);
		set_text_entry("lbl_dungeon"     , "-"	);

		set_text_entry("lbl_rank"	 , "-"  );
		set_text_entry("lbl_total"       , "-"  );
		set_text_entry("lbl_xp"          , "-"  );
		
		#TODO: ::: :: : : :
		#Reset minigame values!!!!!!!!!! #
		#
		#
		#
		
}





sub on_File_Play_Runescape_activate 		{ destination_url( $url_game		)  }
sub on_File_Play_Runescape_Classic_activate   	{ destination_url( $url_classic		)  }
sub on_File_Home_activate 	   		{ destination_url( "file://" . $splash  )  }
#TODO: add text file of fansites (optional) which will be read in here,
# and listed under "Links" on the toolbar.





sub on_about_clicked {
	our $about = $builder->get_object( 'aboutdialog' );
	$about->run;
	$about->hide;
}


	
sub on_map_clicked {
#$mapzoom = 1;
	
	our $mapwindow = Gtk2::Window->new;
		$mapwindow->set_title("RuneMage - Map Viewer"); 
		$mapwindow->set_default_size(800, 600); 
		$mapwindow->set_border_width(8);
		
	our $mapfile = Gtk2::Gdk::Pixbuf->new_from_file("data/rsmap.png"); 

	our $imageviewer = Gtk2::ImageView->new;
		$imageviewer->set_pixbuf($mapfile, TRUE);
		$imageviewer->set_black_bg(TRUE);
		$imageviewer->set_fitting(FALSE);
		$imageviewer->set_zoom ($mapzoom); 
		$imageviewer->set_offset(3713/2, 3329/2);
	our $maphbox = Gtk2::HBox->new(FALSE, 5);	
	our $mapvbox = Gtk2::VBox->new(FALSE, 5);
	


	our $mapbuttonzoomout = Gtk2::Button->new( 'Zoom Out' );
		$mapbuttonzoomout->signal_connect( clicked => sub{ 
					$mapzoom = ($mapzoom - 0.25); 
					$imageviewer->set_zoom( $mapzoom );
		} );
		
	our $mapbuttonzoomin = Gtk2::Button->new( 'Zoom In' );
		$mapbuttonzoomin->signal_connect( clicked => sub{ 
					$mapzoom = ($mapzoom + 0.25); 
					$imageviewer->set_zoom( $mapzoom );
		} );
		

	our $mapbuttongame = Gtk2::Button->new( 'RSC Map' );
		$mapbuttongame->signal_connect( clicked => sub{ 
			if ($mapbuttongame->get_label eq 'RSC Map') {
				$imageviewer->hide;
				$mapbuttongame->set_label( 'RS2 Map');
				our $mapfile = Gtk2::Gdk::Pixbuf->new_from_file("data/rscmap.png");
				$imageviewer->set_pixbuf($mapfile, TRUE);
				$imageviewer->set_zoom (1.00);
				$imageviewer->set_offset((3713/2)-800, (3329/2)-600);
				$imageviewer->show;
			} else {
				$imageviewer->hide;
				$mapbuttongame->set_label( 'RSC Map');
				our $mapfile = Gtk2::Gdk::Pixbuf->new_from_file("data/rsmap.png"); 
				$imageviewer->set_pixbuf($mapfile, TRUE);
				$imageviewer->set_zoom (1.00);
				$imageviewer->set_offset(2152/2, 1007/2);
				$imageviewer->show;
			}

		} );
	
	
						#expand #fill #padding
		$mapvbox->pack_start($maphbox, FALSE, TRUE, 0);
		
		$mapwindow->add( $mapvbox );
		
		$mapvbox->add($maphbox);
		$mapvbox->add($imageviewer);
		
		$maphbox->add($mapbuttonzoomout);
		$maphbox->add($mapbuttonzoomin);
		$maphbox->add($mapbuttongame);
		$mapwindow->show_all;
		
}




sub on_btnZoomOut_clicked {
	$mapzoom = ($mapzoom - 0.20); 
	$imageviewer->set_zoom( $mapzoom );
}
sub on_btnZoomIn_clicked {
	$mapzoom = ($mapzoom + 0.20); 
	$imageviewer->set_zoom( $mapzoom );
}


sub zoom_map {



    if ($_[1]->button == 1) {
        $mapzoom = ($mapzoom + 0.10);
    }
   
    #right mouse button
    elsif ($_[1]->button == 3) {
        $mapzoom = ($mapzoom - 0.10);
    }
}


sub on_toggle_view_activate {
	our $sp = $builder->get_object('vbox_sidepane');

	# toggle display of sidepane
	if ($sp->visible == 1) {
		$sp->hide_all(); 
	} else { 
		$sp->show_all(); 
	}
	
}

#TODO: unrefferenced at the moment.
sub on_toggle_sidepane_position_activate {

	our $hbox = $builder->get_object('hbox_main');
	our $sp = $builder->get_object('vbox_sidepane');

		#$hbox->reorder_child( $sp, 0 );  #right
		#$hbox->reorder_child( $sp, 1 );  #left

}


### toggles display of other "expander" sections when selecting
### a different one.
sub on_hs_expander_activate { close_expander( 'ge', 'al' ); }
sub on_ge_expander_activate { close_expander( 'al', 'hs' ); }
sub on_al_expander_activate { close_expander( 'hs', 'ge' ); }


sub close_expander {
	# close all but selected expander panes
	foreach our $section ( @_ ) {
		$builder->get_object( $section . "_expander" )->set_expanded(0);
		
	}
}


#TODO; Rewrite GE/itemdb search utility.
# was very outdated.... PS; official rs website has api for searching
# so no need to scrape html.








#TODO: seems to be more whitespace not being removed (especially with dungeoneering boss kills)
#TODO: error checking.
#TODO: add some more icons to be displayed next to the adventure logs type.
#      ex; show an icon that represents 'loot' if the activity is an item drop. 
sub on_btnAlog_clicked {

	
	
	our $vbox = $builder->get_object('alog_values');
	
	#cleanup previously created labels
	my @children = $vbox->get_children();
	foreach my $child (@children) {
		$child->destroy;
	}
	
	# fetch recent activity from the adventurer's log rss feed
	our $rsn = grab_text_entry('alog_search');
	our $rss = get ( $url_alog . $rsn ) or warn $! ;



	if ( !$rss ) { 
		$builder->get_object('alog_search')->set_text('Error!');
		our $lbl = Gtk2::Label->new;
		$lbl->set_text('Unable to find any data, either the player does not have membership or their adventure log is set to private/friends only.');
		$vbox->add($lbl); $vbox->show_all;
		return; 
	}
	
	
	# loop through text labels 'alog_lbl0' <--> 'alog_lbl9'
	# and set label/tooltip data

        our ( $xml, $i ) = ( XMLin( $rss ), 0 );
        for ( $i=0; $i<50; $i++ )
        {

		# label we are going to set
		our $lbl = Gtk2::Label->new;
	

		# the labels primary content
		our $lbltext =  ( $i +1 ) . ". $xml->{channel}->{item}->[$i]->{title}";


		# append "..." and cut string if exceeds 25 chars to stop text overflowing
		# and then set the tex to the label

		$lbltext =~ s/^(.{25}).+/$1.../;
		$lbl->set_text($lbltext);

		#formatting
		$lbl->set_justify('left');
		
		# the rss date {pubDate}
		our $rssDate = $xml->{channel}->{item}->[$i]->{pubDate};

		# trim() removes the horrible whitespace from {description}
		our $rssDesc = trim( $xml->{channel}->{item}->[$i]->{description} );


		# remove the time, always 00:00:00... pointless to show
		if ( $rssDate =~ m/(.+)\ (\d+):(\d+):(\d+)\ (.+)/ ) { $rssDate = $1; }

		# set the tooltip
		$lbl->set_tooltip_text( $rssDate . "\n" . $rssDesc );
	
		# pack the label
		$vbox->add($lbl);
	

        }

	$vbox->show_all;
}






sub license {
	print "RuneMage is free software; you can redistribute it and/or modify it  \n";
	print "under the terms of the GNU General Public License as published   \n";
	print "by the Free Software Foundation; either version 2 of the License,\n";
	print "or (at your option) any later version.                           \n\n";
	print "See the included file 'COPYING' for more information\n\n";
}

###EOF###



