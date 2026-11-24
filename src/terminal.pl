
# --- Line editing (pure-Perl readline with arrow key support) ---
# Standard <STDIN> lacks cursor movement. In raw mode via stty, we implement
# navigation (arrows, Backspace, history) without external modules (Term::ReadLine).
{
    my @HISTORY;

    # High-resolution timer helper: Time::HiRes has been part of Perl core since 5.7.3.
    # Sub-second precision is required for CPR (cursor position report) timeouts to avoid
    # integer truncation bugs at second boundaries.
    my $_has_time_hires = eval { require Time::HiRes; 1 };
    sub _has_hires_time { return $_has_time_hires ? 1 : 0 }
    sub _hires_time {
        return $_has_time_hires ? Time::HiRes::time() : time();
    }

    # For debugging: setting $ENV{CLAUDE_DEBUG_INPUT} to a file path logs raw bytes
    # received by read_line_interactive line by line. Temporary mechanism to inspect
    # what arrives during IME input on physical hardware.
    my $_dbg_last_t;
    sub _debug_log {
        return unless $ENV{CLAUDE_DEBUG_INPUT};
        open(my $fh, '>>', $ENV{CLAUDE_DEBUG_INPUT}) or return;
        # Prefix each line with seconds elapsed since previous log. Helps isolate whether
        # Enter is sent immediately upon IME confirmation or after a delay (different input path).
        # Time::HiRes is in Perl 5.8 core, so no extra dependency.
        my $dt = '';
        if (_has_hires_time()) {
            my $now = _hires_time();
            $dt = defined $_dbg_last_t ? sprintf('+%.3f ', $now - $_dbg_last_t) : '+0.000 ';
            $_dbg_last_t = $now;
        }
        # Elements of @_ are aliases to caller arguments, and string literals may be passed
        # directly. Modifying them in-place with s/// causes "Modification of a read-only value attempted"
        # (which previously caused a crash at startup). Always copy to a new variable before modifying.
        my $msg = join('', @_);
        $msg =~ s/^/$dt/mg if $dt ne '';
        print $fh $msg;
        close $fh;
    }

    # Return byte length of a UTF-8 character from its leading byte
    sub _utf8_char_len {
        my ($byte) = @_;
        my $b = ord($byte);
        return 1 if $b < 0x80;
        return 2 if ($b & 0xE0) == 0xC0;
        return 3 if ($b & 0xF0) == 0xE0;
        return 4 if ($b & 0xF8) == 0xF0;
        return 1;  # Advance 1 byte for invalid byte sequences
    }

    # Terminal display width: halfwidth=1, fullwidth=2 (CJK East Asian Width)
    sub _char_width {
        my ($ch) = @_;
        my $cp = ord($ch);
        return (
            ($cp >= 0x1100 && $cp <= 0x115F) ||
            ($cp >= 0x2E80 && $cp <= 0xA4CF) ||
            ($cp >= 0xAC00 && $cp <= 0xD7A3) ||
            ($cp >= 0xF900 && $cp <= 0xFAFF) ||
            ($cp >= 0xFF00 && $cp <= 0xFF60) ||
            ($cp >= 0xFFE0 && $cp <= 0xFFE6)
        ) ? 2 : 1;
    }

    sub _display_width_chars {
        my ($text) = @_;
        my $w = 0;
        $w += _char_width($_) for split //, $text;
        return $w;
    }

    sub _display_width {
        my ($bytes) = @_;
        return 0 if $bytes eq '';
        return _display_width_chars(decode('UTF-8', $bytes, FB_DEFAULT));
    }

    # Return terminal (rows, cols); fallback if unable to obtain or 0.
    #
    # In some environments (verified on PowerMac G4: Mac OS X 10.4.0, build 8A428),
    # stty size may return "0 0" even when normal. Using 0 as columns causes _walk_position
    # to always return (0, 0), locking the cursor to column 0 (which caused Backspace to delete
    # the wrong character after arrow key editing). Values <= 0 are rejected as invalid.
    sub _term_size {
        my $wh = `stty size 2>/dev/null`;
        if ($wh =~ /^\s*(\d+)\s+(\d+)\s*$/ && $2 > 0) {
            my ($rows, $cols) = ($1, $2);
            return ($rows > 0 ? $rows : 24, $cols);
        }
        return (24, 80);
    }

    # Directly query terminal for current cursor row (1-based) via CPR
    # (\x1b[6n -> terminal replies \x1b[<row>;<col>R, a standard VT100 feature).
    # Always wait with a timeout to prevent hanging on unresponsive/broken environments
    # (terminals without CPR support, STDIN not a real terminal, etc.). If unobtainable,
    # return undef and caller proceeds with unknown position.
    #
    # Important: while waiting for CPR reply, the user may start pressing keys
    # (e.g. right after previous turn's output). As soon as a read byte deviates from the CPR
    # response format, all bytes read so far are restored to $pending_ref.
    # Strict format verification prevents swallowing genuine user input mistaken for CPR.
    sub _query_cursor_row {
        my ($pending_ref) = @_;
        print "\x1b[6n";
        my $deadline = _hires_time() + 0.35;
        my @consumed;

        my $read_raw = sub {
            my $remain = $_has_time_hires ? ($deadline - _hires_time()) : 0.15;
            return undef if $_has_time_hires && $remain <= 0;
            $remain = 0.05 if $remain <= 0;
            my $rin = '';
            vec($rin, fileno(STDIN), 1) = 1;
            my $nfound = select(my $rout = $rin, undef, undef, $remain);
            return undef unless $nfound;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        my $give_up = sub {
            unshift @$pending_ref, @consumed;
            return undef;
        };

        my $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq "\x1b";

        $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq '[';

        my $row = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq ';';
            return $give_up->() unless $c =~ /[0-9]/;
            $row .= $c;
        }
        return $give_up->() if $row eq '';

        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq 'R';
            return $give_up->() unless $c =~ /[0-9]/;
        }

        return $row + 0;
    }

    # Same as _query_cursor_row, but also returns column number.
    # Used by _probe_terminal_size to measure actual terminal rows/cols via cursor movement.
    sub _query_cursor_pos {
        my ($pending_ref) = @_;
        print "\x1b[6n";
        my $deadline = _hires_time() + 0.35;
        my @consumed;

        my $read_raw = sub {
            my $remain = $_has_time_hires ? ($deadline - _hires_time()) : 0.15;
            return undef if $_has_time_hires && $remain <= 0;
            $remain = 0.05 if $remain <= 0;
            my $rin = '';
            vec($rin, fileno(STDIN), 1) = 1;
            my $nfound = select(my $rout = $rin, undef, undef, $remain);
            return undef unless $nfound;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        my $give_up = sub {
            unshift @$pending_ref, @consumed;
            return (undef, undef);
        };

        my $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq "\x1b";

        $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq '[';

        my $row = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq ';';
            return $give_up->() unless $c =~ /[0-9]/;
            $row .= $c;
        }
        return $give_up->() if $row eq '';

        my $col = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq 'R';
            return $give_up->() unless $c =~ /[0-9]/;
            $col .= $c;
        }
        return $give_up->() if $col eq '';

        return ($row + 0, $col + 0);
    }

    # Measure real terminal rows and columns directly via cursor movement + CPR without relying on stty size.
    # Following the PowerMac G4 issue where stty size returned "0 0", hardware logs on PowerBook G4
    # revealed units returning row counts significantly smaller than the actual window (e.g. reporting 32 rows
    # for a 44-row window, triggering premature scroll-avoidance newlines when plenty of room remained).
    # stty size only returns the pty driver's value, which can desync from the terminal emulator window.
    # Instead, moving the cursor far off-screen (row 500, col 500) and querying its position causes the
    # terminal to clamp to the bottom-right corner (standard VT100 behavior), directly revealing the exact
    # dimensions. The cursor is then restored to its original position. Returns (measured rows, measured cols,
    # initial cursor row for $start_row). In environments where CPR does not respond, returns undef and caller
    # falls back to stty size.
    sub _probe_terminal_size {
        my ($pending_ref) = @_;
        my ($row0, $col0) = _query_cursor_pos($pending_ref);
        _debug_log(sprintf("[probe] initial pos: row=%s col=%s\n",
            defined $row0 ? $row0 : 'undef', defined $col0 ? $col0 : 'undef'));
        return (undef, undef, undef) unless defined $row0;
        # 4 digits (9999) caused unresponsive CPR on some older terminal implementations
        # that assumed fixed-digit parameters, so reduced to a safe 3 digits (500).
        # Real terminals rarely exceed 500 rows/cols, so 500 is more than enough for probing.
        print "\x1b[500;500H";
        my ($max_row, $max_col) = _query_cursor_pos($pending_ref);
        _debug_log(sprintf("[probe] after CUP 500;500: max_row=%s max_col=%s\n",
            defined $max_row ? $max_row : 'undef', defined $max_col ? $max_col : 'undef'));
        print "\x1b[${row0};${col0}H";
        return (undef, undef, $row0) unless defined $max_row;

        # Confirmed in hardware logs: rapid sequential prompts (e.g. pressing Enter on empty line)
        # can cause overlapping CPR replies if previous reply is still in-flight or delayed.
        # While strict syntax check might pass (matches ESC [ num ; num R), bogus values like "col 1"
        # could be adopted, causing disastrous character-by-character line wraps. Real terminal
        # dimensions are never that small, so obviously invalid values are treated as probe failures
        # and fallback to stty size.
        if ($max_row < 3 || $max_col < 10) {
            _debug_log(sprintf("[probe] measured size looks implausible (%dx%d), discarding\n",
                $max_row, $max_col));
            return (undef, undef, $row0);
        }
        return ($max_row, $max_col, $row0);
    }

    # Given decoded string $text and terminal width $cols, return (0-based row, 0-based col)
    # where cursor will be positioned after rendering.
    #
    # Rather than simply dividing total width by cols, characters are placed one by one.
    # When a fullwidth character (width 2) encounters only 1 remaining column at end of line,
    # the terminal does not render half the character; it wraps the entire character to next line
    # (leaving the last cell blank). Simple width division cannot account for this remainder,
    # which previously caused cursor drift and visual corruption during multibyte input.
    #
    # Terminal wrap uses deferred wrap (does not advance line until next character arrives),
    # so filling exactly $cols columns leaves cursor at the last column of that line.
    sub _walk_position {
        my ($text, $cols) = @_;
        return (0, 0) if $cols <= 0;
        my $row = 0;
        my $used = 0;  # Cells used in current row (0..cols)
        for my $ch (split //, $text) {
            my $w = _char_width($ch);
            if ($used + $w > $cols) {
                $row++;
                $used = 0;
            }
            $used += $w;
        }
        my $col = ($used == $cols) ? $cols - 1 : $used;
        return ($row, $col);
    }

    # Interactively read a single line while displaying prompt.
    # Supports arrow keys, Backspace, and (if use_history is true) up/down history recall.
    # Return value: entered line (raw bytes, without newline). undef on EOF (Ctrl-D).
    sub read_line_interactive {
        my ($prompt, $use_history, $color) = @_;
        $use_history = 1 unless defined $use_history;
        $color = '' unless defined $color;

        cursor_show();

        my $orig_stty = `stty -g`;
        chomp $orig_stty;
        my ($term_rows, $term_cols) = _term_size();
        # Without -opost, output post-processing (especially ocrnl) may remain active,
        # turning \r used for redraw into a newline and creating a new line on every keystroke.
        system('stty', 'raw', '-echo', '-opost');

        # Pushback queue for bytes read ahead by mistake, returned to next loop iteration.
        # Used when a byte thought to be part of a multibyte sequence lacks continuation format (10xxxxxx),
        # or when CPR query turns out to be genuine user keystrokes. Kept across the entire read_line_interactive
        # call, so defined before CPR query.
        my @pending;

        # Continuing input near the bottom of the screen can cause redraws to scroll the terminal,
        # burning intermediate input states into scrollback history (ANSI clear only affects visible area).
        # We query cursor start row via CPR, and only when $redraw detects content will exceed
        # the bottom row do we insert a newline to avoid this (see $redraw below). Normal short responses
        # insert no extra newlines. When CPR is unsupported/unresponsive, $start_row remains undef and
        # behavior is unchanged.
        #
        # Also re-probe $term_rows and $term_cols using CPR rather than relying solely on stty size
        # (see _probe_terminal_size). Overwrite only when successfully probed; otherwise fall back
        # to stty size values.
        my ($probed_rows, $probed_cols, $start_row) = _probe_terminal_size(\@pending);
        if (defined $probed_rows) {
            _debug_log(sprintf("[probe] using measured size: %dx%d (stty said %dx%d)\n",
                $probed_rows, $probed_cols, $term_rows, $term_cols));
            $term_rows = $probed_rows;
            $term_cols = $probed_cols;
        } else {
            _debug_log(sprintf("[probe] measurement failed, falling back to stty size: %dx%d\n",
                $term_rows, $term_cols));
        }

        my $buf = '';                    # Raw bytes
        my $pos = 0;                     # Cursor position (in bytes, always at character boundary)
        my $hist_idx = scalar(@HISTORY); # History cursor (end of array = new input in progress)
        my $saved_buf = '';              # Stashed input prior to traversing history

        # Leading newline in $prompt (e.g. "\nUser> ") is only used on initial print.
        # Including it in redraws would insert newlines on every keystroke.
        (my $redraw_prompt = $prompt) =~ s/^\n+//;

        # Initial value is the number of rows occupied by redraw_prompt alone (buf empty).
        my $rows_used = (_walk_position($redraw_prompt, $term_cols))[0] + 1;

        # Row offset of cursor from top of prompt block (0-based).
        # Needed separately from $rows_used (total block height) because left/right arrows
        # can move cursor to an earlier row in multiline input. In initial state (empty buf),
        # cursor is at the end of redraw_prompt.
        my $cursor_display_row = (_walk_position($redraw_prompt, $term_cols))[0];

        my $redraw = sub {
            # $buf is raw UTF-8 bytes. Since STDOUT has :encoding(UTF-8) layer,
            # decode to Perl string before passing, to prevent double-encoding garble.
            my $text   = decode('UTF-8', $buf, FB_DEFAULT);
            my $before = decode('UTF-8', substr($buf, 0, $pos), FB_DEFAULT);
            my $full_text   = $redraw_prompt . $text;
            my $full_width  = _display_width_chars($full_text);
            my $cursor_width = _display_width_chars($redraw_prompt . $before);
            my $end_row = (_walk_position($full_text, $term_cols))[0];

            # Debug logging: records escape sequences sent and underlying calculations.
            # Only active when CLAUDE_DEBUG_INPUT is set. Comparing sent commands with screen
            # output helps determine whether an issue is calculation logic or terminal emulation.
            _debug_log(sprintf(
                "[redraw] term_cols=%d pos=%d buf_hex=%s rows_used_before=%d full_width=%d cursor_width=%d end_row=%d\n",
                $term_cols, $pos, unpack('H*', $buf), $rows_used, $full_width, $cursor_width, $end_row
            ));

            # Lazy bottom-of-screen avoidance: insert newline only at the exact moment
            # content is about to exceed terminal bottom row (proactively reserving space on every
            # prompt would leave empty blank lines in scrollback for short inputs).
            if (defined $start_row && $start_row + $end_row >= $term_rows) {
                my $overflow = $start_row + $end_row - $term_rows + 1;
                _debug_log(sprintf("[redraw] lazy headroom: send %d newline(s), start_row was %d\n",
                    $overflow, $start_row));
                print "\n" x $overflow, "\r";

                # Send newlines to terminal. Since at bottom row, terminal scrolls.
                # Amount to move back up must include not only $cursor_display_row but also $overflow rows
                # just sent by newlines to return to block start.
                my $back = $cursor_display_row + $overflow;
                if ($back > 0) {
                    print "\x1b[" . $back . "A";
                }
                my $measured = _query_cursor_row(\@pending);
                if (defined $measured) {
                    $start_row = $measured;
                } else {
                    # Fallback estimation for environments where CPR is unavailable
                    $start_row -= $overflow;
                    $start_row = 1 if $start_row < 1;
                }
                _debug_log(sprintf("[redraw] lazy headroom: start_row now %d (measured=%s)\n",
                    $start_row, defined $measured ? $measured : 'undef'));
                # Mark cursor as already at block head to prevent duplicate repositioning below.
                $cursor_display_row = 0;
            }

            # Move cursor up by $cursor_display_row (where cursor actually was in previous redraw)
            # and clear from there to end of screen. Must use $cursor_display_row rather than $rows_used
            # because arrow keys may leave cursor in an earlier row; using $rows_used would move
            # too far up and erase previous conversation history above prompt.
            if ($cursor_display_row > 0) {
                _debug_log(sprintf("[redraw] send: CUU %d\n", $cursor_display_row));
                print "\x1b[" . $cursor_display_row . "A";
            }
            # When cursor is in the middle of a line, render text after cursor in reverse video (SGR 7).
            # Helps visually distinguish cursor position on vintage LCD/CRT displays where blinking
            # hardware cursor can be hard to see. SGR control codes have zero width, so layout calculations
            # remain unaffected.
            if ($cursor_width < $full_width) {
                my $after = substr($text, length($before));
                _debug_log(sprintf("[redraw] send: CR + ED0 + text=%s (reverse-video tail after cursor)\n",
                    unpack('H*', encode('UTF-8', $full_text))));
                print "\r\x1b[0J", $color, $redraw_prompt, $before, "\x1b[7m", $after, "\x1b[0m", $color;
            } else {
                _debug_log(sprintf("[redraw] send: CR + ED0 + text=%s\n", unpack('H*', encode('UTF-8', $full_text))));
                print "\r\x1b[0J", $color, $full_text;
            }

            $rows_used = $end_row + 1;
            _debug_log(sprintf("[redraw] rows_used_after=%d\n", $rows_used));

            if ($cursor_width < $full_width) {
                my ($cur_row, $cur_col) = _walk_position($redraw_prompt . $before, $term_cols);
                _debug_log(sprintf("[redraw] cursor not at end: cur_row=%d cur_col=%d\n", $cur_row, $cur_col));
                if ($end_row > $cur_row) {
                    _debug_log(sprintf("[redraw] send: CUU %d\n", $end_row - $cur_row));
                    print "\x1b[" . ($end_row - $cur_row) . "A";
                }
                _debug_log(sprintf("[redraw] send: CHA %d\n", $cur_col + 1));
                print "\x1b[" . ($cur_col + 1) . "G";
                $cursor_display_row = $cur_row;
            } else {
                $cursor_display_row = $end_row;
            }
        };

        if ($color) {
            if ($prompt =~ /^(\n*)(.*)$/s) {
                print $1, $color, $2;
            } else {
                print $color, $prompt;
            }
        } else {
            print $prompt;
        }
        _debug_log("=== read_line_interactive start ===\n");

        # (@pending queue is shared with CPR query and was defined at function start)
        my $read_one_byte = sub {
            return shift @pending if @pending;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        # Mac OS X Tiger Terminal.app sometimes prefixes bytes with 0x16 (Ctrl-V, traditionally LNEXT)
        # when delivering text confirmed via IME. Since this program runs in raw mode and does not interpret
        # LNEXT, unhandled 0x16 would corrupt UTF-8 strings. We skip 0x16 and treat subsequent byte as raw data.
        my $last_was_lnext = 0;   # Was the previous byte 0x16 (LNEXT)?
        my $read_byte = sub {
            my $ch = $read_one_byte->();
            if (defined $ch && $ch eq "\x16") {
                $ch = $read_one_byte->();
                $last_was_lnext = 1;
                _debug_log(sprintf("  (LNEXT 0x16 skipped, next byte: %s)\n",
                    defined $ch ? sprintf('%02x', ord($ch)) : 'eof'));
            }
            else {
                $last_was_lnext = 0;
            }
            return $ch;
        };

        my $result;
        RAW_LOOP: while (1) {
            my $ch = $read_byte->();
            if (!defined $ch) {
                _debug_log("EOF\n");
                print $COLOR_RESET if $color;
                $result = undef;
                last RAW_LOOP;
            }
            my $b = ord($ch);
            _debug_log(sprintf("byte: %02x (%s)\n", $b, ($b >= 0x20 && $b < 0x7f) ? chr($b) : ''));

            if ($b == 13 || $b == 10) {
                # A newline wrapped in 0x16 (LNEXT) comes from IME confirmation rather than an intentional
                # Enter keypress to submit. Terminal.app on Tiger sends confirmed text byte-by-byte with 0x16;
                # confirming during candidate selection could trigger premature submission. Wrapped newlines
                # are discarded; plain Enter (without 0x16) submits normally.
                if ($last_was_lnext) {
                    _debug_log("-> newline via LNEXT: treated as IME-commit, not submit\n");
                    next RAW_LOOP;
                }
                _debug_log(sprintf("-> ENTER, buf hex=%s\n", unpack('H*', $buf)));
                print $COLOR_RESET if $color;
                print "\r\n";
                $result = $buf;
                last RAW_LOOP;
            }
            elsif ($b == 3) {
                print $COLOR_RESET if $color;
                print "\r\n";
                $result = '';
                last RAW_LOOP;
            }
            elsif ($b == 4) {
                if ($buf eq '') {
                    print $COLOR_RESET if $color;
                    $result = undef;
                    last RAW_LOOP;
                }
            }
            elsif ($b == 127 || $b == 8) {      # Backspace
                if ($pos > 0) {
                    my $start = $pos - 1;
                    $start-- while $start > 0 && (ord(substr($buf, $start, 1)) & 0xC0) == 0x80;
                    substr($buf, $start, $pos - $start, '');
                    $pos = $start;
                    $redraw->();
                }
            }
            elsif ($b == 27) {
                my $c2 = $read_byte->();
                next RAW_LOOP unless defined $c2;
                if ($c2 eq '[') {
                    my $c3 = $read_byte->();
                    next RAW_LOOP unless defined $c3;
                    if ($c3 eq 'C') {            # →
                        if ($pos < length($buf)) {
                            $pos += _utf8_char_len(substr($buf, $pos, 1));
                            $redraw->();
                        }
                    }
                    elsif ($c3 eq 'D') {         # ←
                        if ($pos > 0) {
                            my $start = $pos - 1;
                            $start-- while $start > 0 && (ord(substr($buf, $start, 1)) & 0xC0) == 0x80;
                            $pos = $start;
                            $redraw->();
                        }
                    }
                    elsif ($use_history && $c3 eq 'A') {  # Up arrow: go back in history
                        if ($hist_idx > 0) {
                            $saved_buf = $buf if $hist_idx == @HISTORY;
                            $hist_idx--;
                            $buf = $HISTORY[$hist_idx];
                            $pos = length($buf);
                            $redraw->();
                        }
                    }
                    elsif ($use_history && $c3 eq 'B') {  # Down arrow: go forward in history
                        if ($hist_idx < @HISTORY) {
                            $hist_idx++;
                            $buf = ($hist_idx == @HISTORY) ? $saved_buf : $HISTORY[$hist_idx];
                            $pos = length($buf);
                            $redraw->();
                        }
                    }
                    elsif ($c3 =~ /[0-9;]/) {
                        my $params = $c3;
                        my $final;
                        while (1) {
                            my $cx = $read_byte->();
                            last unless defined $cx;
                            if ($cx =~ /[0-9;]/) { $params .= $cx; next; }
                            $final = $cx;
                            last;
                        }
                        if (defined $final && $final eq '~' && $params eq '3') {
                            # Delete key (ESC [ 3 ~)
                            if ($pos < length($buf)) {
                                substr($buf, $pos, _utf8_char_len(substr($buf, $pos, 1)), '');
                                $redraw->();
                            }
                        }
                        # Discard everything else (especially $final eq 'R' = delayed CPR cursor position report).
                        # When prompts start in rapid succession, delayed CPR responses (e.g. "\x1b[32;59R")
                        # could arrive mixed with input. Consuming the whole CSI sequence here prevents corrupting the buffer.
                        _debug_log(sprintf("[input] swallowed CSI: ESC [ %s %s\n",
                            $params, defined $final ? $final : '(eof)'));
                    }
                }
            }
            else {
                # Wait until all bytes of a multibyte character arrive before adding to buffer and redrawing,
                # otherwise decode() will turn incomplete sequences into replacement characters. If subsequent
                # byte is not a valid UTF-8 continuation byte (10xxxxxx), restore it to pending queue.
                my $need = _utf8_char_len($ch) - 1;
                my $char = $ch;
                while ($need > 0) {
                    my $cont = $read_byte->();
                    last unless defined $cont;
                    _debug_log(sprintf("  continuation byte: %02x\n", ord($cont)));
                    if ((ord($cont) & 0xC0) != 0x80) {
                        unshift @pending, $cont;
                        last;
                    }
                    $char .= $cont;
                    $need--;
                }
                substr($buf, $pos, 0) = $char;
                $pos += length($char);

                # Fast path: when cursor is at end of line (append only) and this character causes
                # neither line wrap nor scroll-avoidance newline, print the character directly rather than
                # redrawing the entire line. Full redraw on every keystroke causes noticeable flicker on slow
                # vintage hardware (reported on PowerBook G4). Redraw only on operations that shift positions
                # (wrap, insertion, arrows, history, Backspace).
                my $fast = 0;
                if ($pos == length($buf)) {
                    my $new_full = $redraw_prompt . decode('UTF-8', $buf, FB_DEFAULT);
                    my ($nr, $nc) = _walk_position($new_full, $term_cols);
                    if ($nr == $rows_used - 1
                        && $nc <= $term_cols - 2
                        && !(defined $start_row
                             && $start_row + $nr >= $term_rows))
                    {
                        print decode('UTF-8', $char, FB_DEFAULT);
                        $cursor_display_row = $nr;
                        _debug_log(sprintf("[fast] append 1 char, pos=%d nc=%d\n", $pos, $nc));
                        $fast = 1;
                    }
                }
                $redraw->() unless $fast;
            }
        }

        system('stty', $orig_stty) if defined $orig_stty && $orig_stty ne '';
        print $COLOR_RESET if $color;

        if ($use_history && defined $result && $result ne '') {
            push @HISTORY, $result;
        }
        cursor_hide();
        return $result;
    }
}

