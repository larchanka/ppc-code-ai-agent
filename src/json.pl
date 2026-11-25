# --- Minimal JSON encoder/decoder (zero dependencies, recursive descent) ---
package MiniJSON;

no warnings 'recursion';
use B ();

sub encode {
    my ($v) = @_;
    my $r = ref $v;
    if ($r eq 'HASH') {
        return '{' . join(',', map {
            encode_string($_) . ':' . encode($v->{$_})
        } sort keys %$v) . '}';
    } elsif ($r eq 'ARRAY') {
        return '[' . join(',', map { encode($_) } @$v) . ']';
    } elsif (!defined $v) {
        return 'null';
    } elsif ($r eq 'SCALAR') {
        return $$v ? 'true' : 'false';
    } else {
        my $flags = B::svref_2object(\$v)->FLAGS;
        if (($flags & (B::SVf_IOK | B::SVf_NOK)) && !($flags & B::SVf_POK)) {
            return $v;
        } elsif ($flags & B::SVf_POK) {
            return encode_string($v);
        } elsif ($flags & (B::SVf_IOK | B::SVf_NOK)) {
            return $v;
        } elsif ($v =~ /^-?\d+(\.\d+)?([eE][+-]?\d+)?$/) {
            return $v;
        } else {
            return encode_string($v);
        }
    }
}

sub encode_string {
    my ($s) = @_;
    return '""' unless defined $s;
    $s =~ s/([\\"])/\\$1/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/([\x00-\x1f])/sprintf('\\u%04x', ord($1))/ge;
    return '"' . $s . '"';
}

# decode: string -> Perl data structure. Parses while advancing pos.
sub decode {
    my ($text) = @_;
    die "JSON parse error: empty input\n" unless defined $text && $text =~ /\S/;
    my $pos = 0;
    my $val = _decode_value(\$text, \$pos);
    return $val;
}

sub _skip_ws {
    my ($t, $p) = @_;
    my $len = length($$t);
    $$p++ while $$p < $len && substr($$t, $$p, 1) =~ /[\s]/;
}

sub _decode_value {
    my ($t, $p) = @_;
    _skip_ws($t, $p);
    return undef if $$p >= length($$t);
    my $c = substr($$t, $$p, 1);
    if ($c eq '{') { return _decode_object($t, $p); }
    if ($c eq '[') { return _decode_array($t, $p); }
    if ($c eq '"') { return _decode_string($t, $p); }
    if (substr($$t, $$p, 4) eq 'true') {
        my $after = substr($$t, $$p + 4, 1);
        if ($after eq '' || $after =~ /[\s,\]\}]/) {
            $$p += 4;
            return 1;
        }
    }
    if (substr($$t, $$p, 5) eq 'false') {
        my $after = substr($$t, $$p + 5, 1);
        if ($after eq '' || $after =~ /[\s,\]\}]/) {
            $$p += 5;
            return 0;
        }
    }
    if (substr($$t, $$p, 4) eq 'null') {
        my $after = substr($$t, $$p + 4, 1);
        if ($after eq '' || $after =~ /[\s,\]\}]/) {
            $$p += 4;
            return undef;
        }
    }
    if (substr($$t, $$p) =~ /^(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/) {
        $$p += length($1);
        return $1 + 0;
    }
    die "JSON parse error at pos $$p: " . substr($$t, $$p, 30) . "\n";
}

sub _decode_object {
    my ($t, $p) = @_;
    my %h;
    $$p++;
    _skip_ws($t, $p);
    if ($$p < length($$t) && substr($$t, $$p, 1) eq '}') {
        $$p++;
        return \%h;
    }
    while (1) {
        _skip_ws($t, $p);
        my $key = _decode_string($t, $p);
        _skip_ws($t, $p);
        $$p++;
        my $val = _decode_value($t, $p);
        $h{$key} = $val;
        _skip_ws($t, $p);
        my $c = substr($$t, $$p, 1);
        if ($c eq ',') { $$p++; next; }
        if ($c eq '}') { $$p++; last; }
        die "JSON parse error in object at pos $$p\n";
    }
    return \%h;
}

sub _decode_array {
    my ($t, $p) = @_;
    my @a;
    $$p++;
    _skip_ws($t, $p);
    if ($$p < length($$t) && substr($$t, $$p, 1) eq ']') {
        $$p++;
        return \@a;
    }
    while (1) {
        my $val = _decode_value($t, $p);
        push @a, $val;
        _skip_ws($t, $p);
        my $c = substr($$t, $$p, 1);
        if ($c eq ',') { $$p++; next; }
        if ($c eq ']') { $$p++; last; }
        die "JSON parse error in array at pos $$p\n";
    }
    return \@a;
}

sub _decode_string {
    my ($t, $p) = @_;
    $$p++;
    my $out = '';
    my $len = length($$t);
    while (1) {
        die "unterminated string\n" if $$p >= $len;
        my $c = substr($$t, $$p, 1);
        if ($c eq '"') {
            $$p++;
            last;
        }
        if ($c eq '\\') {
            $$p++;
            die "unterminated string\n" if $$p >= $len;
            my $e = substr($$t, $$p, 1);
            if ($e eq 'n') {
                $out .= "\n";
                $$p++;
            } elsif ($e eq 't') {
                $out .= "\t";
                $$p++;
            } elsif ($e eq 'r') {
                $out .= "\r";
                $$p++;
            } elsif ($e eq 'b') {
                $out .= "\b";
                $$p++;
            } elsif ($e eq 'f') {
                $out .= "\f";
                $$p++;
            } elsif ($e eq '"' || $e eq '\\' || $e eq '/') {
                $out .= $e;
                $$p++;
            } elsif ($e eq 'u') {
                if ($$p + 4 >= $len || substr($$t, $$p + 1, 4) !~ /^[0-9a-fA-F]{4}$/) {
                    die "JSON parse error: invalid \\u escape at pos $$p\n";
                }
                my $u1 = hex(substr($$t, $$p + 1, 4));
                $$p += 5;

                if ($u1 >= 0xD800 && $u1 <= 0xDBFF) {
                    if ($$p + 5 < $len && substr($$t, $$p, 2) eq '\\u' && substr($$t, $$p + 2, 4) =~ /^[0-9a-fA-F]{4}$/) {
                        my $u2 = hex(substr($$t, $$p + 2, 4));
                        if ($u2 >= 0xDC00 && $u2 <= 0xDFFF) {
                            my $cp = 0x10000 + (($u1 - 0xD800) << 10) + ($u2 - 0xDC00);
                            $out .= pack("U*", $cp);
                            $$p += 6;
                        } else {
                            $out .= pack("U*", 0xFFFD);
                        }
                    } else {
                        $out .= pack("U*", 0xFFFD);
                    }
                } elsif ($u1 >= 0xDC00 && $u1 <= 0xDFFF) {
                    $out .= pack("U*", 0xFFFD);
                } else {
                    $out .= pack("U*", $u1);
                }
            } else {
                $out .= $e;
                $$p++;
            }
        } else {
            $out .= $c;
            $$p++;
        }
    }
    return $out;
}

package main;

1;

