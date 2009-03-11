#!/usr/bin/perl
# HELLO
#A irssi perl script to interact with MPD
#Copyright (C) 2006 James Rosten <fhatsoft@gmail.com>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 
 
# # # # # # # # # # # # # #
#       Changelog         #
# # # # # # # # # # # # # #
# 0.1
#    That was a blur.
# 0.1 to 0.1.2
#    Still a blur.
# 0.2
#    Added _get_bitrate and _get_status.
# 0.2.1
#    Made the _connect even better (added a ping before reconnect).
# 0.3
#    Configured differently (done through Irssi variables).
# 0.4
#    Added play, pause, and stop functions and reverted back to old _connect because of a slight bug
# 0.5
#    Added volume setting and getting support.
# 0.6
#    Added a progress bar to the status message.
# END CHANGELOG
 
 
# # # # # # # # # # # # # #
#      The Beginning      #
# # # # # # # # # # # # # #
use strict;
use IO::Socket;
use Irssi;
use vars qw{$VERSION %IRSSI %config};
 
 
$VERSION = '0.4';
%IRSSI = (
    authors        => "James Rosten",
    contact        => 'fhatsoft@gmail.com',
    name           => "MPD irssi script",
    description    => "Controls MPD",
    license        => "GPLv2",
);
 
 
Irssi::settings_add_str('mpd', 'mpd_host', 'localhost');
Irssi::settings_add_str('mpd', 'mpd_port', '6600');
Irssi::settings_add_str('mpd', 'mpd_timeout', 15);
 
 
$config{'host'} = Irssi::settings_get_str('mpd_host');
$config{'port'} = Irssi::settings_get_str('mpd_port');
$config{'timeout'} = Irssi::settings_get_str('mpd_timeout');
 
 
my $socket = IO::Socket::INET->new( Proto => 'tcp', 
                                                                        PeerPort => $config{'port'}, 
                                                                        PeerAddr => $config{'host'}, 
                                                                        timeout => $config{'timeout'} );
if ( not $socket ) {
    die "Error: ".$!;
}
 
 
# THE END OF THE BEGINNING
 
 
# # # # # # # # # # # # # #
#   The Internal Stuff    #
# # # # # # # # # # # # # #
sub _connect
{
    print $socket "close\n";
    undef $socket;
    $socket = new IO::Socket::INET( PeerAddr => $config{'host'}, PeerPort => $config{'port'}, Proto => "tcp", timeout => 15 );
    die "Could not create socket: $!\n" unless $socket;
    if ( not $socket->getline() =~ /^OK MPD*/ ) {
        die "Could not connect: $!\n";
    }
    return 1;
}
 
 
sub _get_time
{
    _connect;
    print $socket "status\n";
    my $ans = "";
    while ( not $ans =~ /^(OK|ACK)/ ) {
        $ans = <$socket>;
        if ( $ans =~ /^time:\s(.+)$/ ) {
            if ( $1 =~ /^(.+):(.+)/ ) {
                my $val = 100 * ($1/$2);
                my $str;
                if ( $val <= 0 ) {
                    $str = '<---------->';
                } elsif ( $val > 0 and $val < 20 ) {
                    $str = '<%--------->';
                } elsif ( $val >= 20 and $val < 30 ) {
                    $str = '<%%-------->';
                } elsif ( $val >= 30 and $val < 40 ) {
                    $str = '<%%%------->';
                } elsif ( $val >= 40 and $val < 50 ) {
                    $str = '<%%%%------>';
                } elsif ( $val >= 50 and $val < 60 ) {
                    $str = '<%%%%%----->';
                } elsif ( $val >= 60 and $val < 70 ) {
                    $str = '<%%%%%%---->';
                } elsif ( $val >= 70 and $val < 80 ) {
                    $str = '<%%%%%%%--->';
                } elsif ( $val >= 80 and $val < 90 ) {
                    $str = '<%%%%%%%%-->';
                } elsif ( $val >= 90 and $val < 100 ) {
                    $str = '<%%%%%%%%%->';
                } elsif ( $val == 100 ) {
                    $str = '<%%%%%%%%%%>';
                }
                return sprintf("%02d%% :: %d:%02d/%d:%02d %s", (100 * ($1 / $2)), ($1 / 60), ($1 % 60), ($2 / 60), ($2 % 60), $str);
            }
        }
    }
}
 
 
sub _get_bitrate
{
    _connect;
    print $socket "status\n";
    my $ans = "";
    while ( not $ans =~ /^(OK|ACK)/ ) {
        $ans = <$socket>;
        if ( $ans =~ /^bitrate:\s(.+)$/ ) {
            return $1;
        }
    }
}
 
 
sub _get_status
{
    _connect;
    print $socket "status\n";
    my $ans = "";
    while ( not $ans =~ /^(OK|ACK)/ ) {
        $ans = <$socket>;
        if ( $ans =~ /^state:\s(.+)$/ ) {
            return $1;
        }
    }
}
 
 
sub _get_volume
{
    _connect;
    print $socket "status\n";
    my $ans = "";
    while ( not $ans =~ /^(OK|ACK)/ ) {
        $ans = <$socket>;
        if ( $ans =~ /^volume:\s(.+)$/ ) {
            return $1;
        }
    }
}
# END OF THE INTERNAL STUFF
 
 
# # # # # # # # # # # # # 
#  All that Good Stuff  #
# # # # # # # # # # # # #
sub mpd_help 
{
    Irssi::print "MPD Now Playing irssi script. Version 0.5
James Rosten (C) 2006   
Variables:
    mpd_host     (localhost)
    mpd_port     (6600)
    mpd_timeout  (15)
Usage:
    /np                    Displays information about the current song.
    /nphelp                Displays this message.
    /next                  Play next song on the playlist.
    /prev                  Play previous song from the playlist.
    /shuffle               Shuffle the current playlist.
    /play                  Start playing.
    /pause                 Pause.
    /stop                  Stop mpd.
    /vol [volume]          Sets the volume, if there is no volume argument, then it says the current volume."
}
 
 
sub mpd_np
{
    my ($data, $server, $witem) = @_;
    _connect;
    print $socket "currentsong\n";
    my $ans = "";
    my $fn = "";
    my $artist = "0";
    my $title = "0";
    while ( not $ans =~ /^(OK|ACK)/ ) {
        $ans = <$socket>;
        if ( $ans =~ /file: (.+)$/) {
            $fn = $1;
            $fn =~ s/.*\///;
        } elsif ( $ans =~ /^Artist: (.+)$/ ) {
            $artist = $1;
        } elsif ( $ans =~ /Title: (.+)$/ ) {
            $title = $1;
        }
    }
    my $state = _get_status;
    if ( $state eq '' ) {
        $state = 'playing';
    } elsif ( $state eq 'stop' ) {
        $state = 'playing';
    } elsif ( $state eq 'play' ) {
        $state = 'playing';
    }
    if ( $witem and ( $witem->{type} eq "CHANNEL" or $witem->{type} eq "QUERY" ) ) {
        if ( $title and $artist ) {
            $witem->command( "/me is ".$state.": ".$artist." - ".$title."  ");
        } else {
            $witem->command( "/me is ".$state.": ".$fn." " );
        }
    }
}
 
 
sub mpd_next
{
    _connect;
    print $socket "next\n" if $socket;
}
 
 
sub mpd_prev
{
    _connect;
    print $socket "previous\n" if $socket;
}
 
 
 
 
sub mpd_shuffle
{
    _connect;
    print $socket "shuffle\n" if $socket;
}
 
 
sub mpd_pause
{
    _connect;
    print $socket "pause\n" if $socket;
}
 
 
sub mpd_play
{
    _connect;
    print $socket "play\n" if $socket;
}
 
 
sub mpd_stop
{
    _connect;
    print $socket "stop\n" if $socket;
}
 
 
sub mpd_vol
{
    my ($data, $server, $witem) = @_;
    if ( not $data ) {
        _connect;
        Irssi::print "Current Volume: "._get_volume;
        return;
    }
    _connect;
    print $socket "setvol ".$data."\n" if $socket;
}
 
 
Irssi::command_bind 'np'             => \&mpd_np;
Irssi::command_bind 'nphelp'         => \&mpd_help;
Irssi::command_bind 'next'           => \&mpd_next;
Irssi::command_bind 'prev'           => \&mpd_prev;
Irssi::command_bind 'shuffle'        => \&mpd_shuffle;
Irssi::command_bind 'pause'          => \&mpd_pause;
Irssi::command_bind 'play'           => \&mpd_play;
Irssi::command_bind 'stop'           => \&mpd_stop;
Irssi::command_bind 'vol'            => \&mpd_vol;
