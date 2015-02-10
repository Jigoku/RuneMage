#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Gtk2 '-init';
use Gtk2::WebKit;


my $window = Gtk2::Window->new;
my $webkit = Gtk2::WebKit::WebView->new;
my $container = Gtk2::ScrolledWindow->new;

my $settings = Gtk2::WebKit::WebSettings->new;	
		$settings->set_property('enable-java-applet', 1);
		$settings->set_property('enable-plugins', 1);
		$webkit->set_settings($settings);



package main;

	$window->set_title( 'Test' );
	$window->set_default_size( 800, 600 );
	$window->signal_connect ( destroy => sub { Gtk2->main_quit; } );
	
	$window->add( $container );
	$container->add( $webkit );
	$webkit ->load_uri( "http://www.java.com/en/download/installed.jsp?detect=jre&try=1" );
	
	$window->show_all();

	Gtk2->main();



	


