#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Gtk2 -init;
use Gtk2::Ex::Dialogs;
use Glib ':constants';

my %gui_strings = (
    id_empty_error_title => "Error: empty id",
    id_empty_error_text => "You did not give a valid identifier.",
    assistant1_title => "Id",
    assistant2_title => "Confirm",
    assistant2_label => "Well done!",
);


my $id;

my $assistant = Gtk2::Assistant->new;
Gtk2::Ex::Dialogs->set_parent_window( $assistant );
$assistant->signal_connect (delete_event => sub { Gtk2->main_quit; });
+ 

my $page = Gtk2::Entry->new();
$assistant->append_page ($page);
$assistant->set_page_title ($page, $gui_strings{assistant1_title});
$assistant->set_page_complete ($page, TRUE);
$assistant->set_page_type ($page, 'intro');
$page->show_all;    

my $page2 = Gtk2::Label->new($gui_strings{assistant2_label});
$page2->show;
$assistant->append_page ($page2);
$assistant->set_page_title ($page2, $gui_strings{assistant2_title});
$assistant->set_page_complete ($page2, TRUE);
$assistant->set_page_type ($page2, 'confirm');

$assistant->signal_connect (cancel => \&cancel_callback);
$assistant->signal_connect (close => \&cancel_callback);
$assistant->signal_connect (apply => sub {
        # do whatever we have to do with the id, here we just print it
        print $id."\n";
    });
$assistant->signal_connect (prepare => sub {
        my $page_num = $assistant->get_current_page();
        $id = $page->get_text();
        if ($page_num == 1 and $id eq "") {
            new_and_run Gtk2::Ex::Dialogs::ErrorMsg ( title => $gui_st
+rings{id_empty_error_title},
                                                     text => $gui_stri
+ngs{id_empty_error_text} );
            $assistant->set_current_page(0);
            return;
        } 
    });

$assistant->show_all;
Gtk2->main;


sub cancel_callback {
  my $widget = shift;
  
  $widget->destroy;
  Gtk2->main_quit; 
}