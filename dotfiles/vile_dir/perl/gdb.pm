package gdb;

use strict;
use shell;

require Vile::Exporter;

use vars qw(@ISA %REGISTRY);

@ISA      = 'Vile::Exporter';
%REGISTRY = (
    'gdb' => [ \&gdb_session, 'start or rejoin an interactive gdb session' ],
    'gdb-break' => [ \&gdb_break, 'set a breakpoint in gdb' ],
    'gdb-step'  => [ \&gdb_step,  'single step in gdb' ],
    'gdb-next'  => [ \&gdb_next,  'next in gdb' ],
    'gdb-cont'  => [ \&gdb_cont,  'continue in gdb' ],
);

{
    my $gdbid;
    my $old_gdb_cmd = "gdb --fullname ";

    sub find_gdb_session {
        return $gdbid if !shell::dead($gdbid);
        for ( my $i = 0 ; my $w = Vile::window_at($i) ; $i++ ) {
            if ( !shell::dead( shell::buffer_name_internal( $w->buffer ) ) ) {
                my $buffername = $w->buffer->buffername;
                print "Join $buffername as a gdb session? ";
                my $c = Vile::keystroke;
                if ( $c == ord('y') || $c == ord('Y') ) {
                    $gdbid = shell::buffer_name_internal( $w->buffer );
                    return $gdbid;
                }
            }
        }
        my $gdb_cmd = Vile::mlreply_shell( "gdb command line: ", $old_gdb_cmd );
        return undef if !defined($gdb_cmd);
        if ( $gdb_cmd !~ /\s--fullname\b/ ) {
            print "``--fullname'' option missing.  Shall I add it? ";
            my $c = Vile::keystroke;
            if ( $c == ord('y') || $c == ord('Y') ) {
                $gdb_cmd =~ s/^(\s*\S+)(.*)$/$1 --fullname$2/;
            }
        }
        $old_gdb_cmd = $gdb_cmd;
        $gdbid       = shell::shell($gdb_cmd);
    }
}

sub gdb_session {
    my $gdbid = find_gdb_session() or return;
    my $curwin = Vile::current_window;
    shell::resume_shell($gdbid);
    $curwin->current_window;
}

sub gdb_break {
    my $b        = Vile::current_buffer;
    my $filename = $b->filename;
    $filename =~ s#.*/##;    # Better chance of working with
                             # just the filename.
    my $lineno = $b->dotq;
    my $gdbid = find_gdb_session() or return;
    shell::send_chars( $gdbid, "break $filename:$lineno\n" );
}

sub gdb_step {
    my $gdbid = find_gdb_session() or return;
    shell::send_chars( $gdbid, "step\n" );
}

sub gdb_next {
    my $gdbid = find_gdb_session() or return;
    shell::send_chars( $gdbid, "next\n" );
}

sub gdb_cont {
    my $gdbid = find_gdb_session() or return;
    shell::send_chars( $gdbid, "continue\n" );
}

sub gdb_interrupt {
    my $gdbid = find_gdb_session() or return;
    shell::send_chars( $gdbid, "\003" );
}

1;

__DATA__

=head1 NAME

gdb - run gdb in a vile window

=head1 SYNOPSIS

In .vilerc:

    perl "use gdb"

In [x]vile:

    :gdb
    :gdb-break
    :gdb-step
    :gdb-next
    :gdb-cont

=head1 DESCRIPTION

The B<gdb> module runs C<gdb> in a vile window and tracks changes in the editor.
This must be used with the C<shell.pm> module.

=head2 gdb

Start or rejoin an interactive gdb session.

=head2 gdb-break

Set a breakpoint in gdb.

=head2 gdb-step

Single step in gdb.

=head2 gdb-next

Next in gdb.

=head2 gdb-cont

Continue in gdb.

=head1 AUTHOR

Kevin Buettner

=cut
