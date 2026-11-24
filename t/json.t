#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
require "$root_dir/code-agent.pl";

# ---------------------------------------------------------------------------
# Group 1: UTF-16 Surrogate Pair Decoding
# ---------------------------------------------------------------------------

# 1.1 Standard surrogate pair (U+1F600 Grinning Face: \uD83D\uDE00)
{
    my $json = q({"emoji":"\uD83D\uDE00"});
    my $data = MiniJSON::decode($json);
    is(ref($data), 'HASH', "Decoded surrogate pair to HASH");
    is(length($data->{emoji}), 1, "Decoded emoji character has length 1");
    is(ord($data->{emoji}), 0x1F600, "Decoded emoji has Unicode codepoint 0x1F600");
    is($data->{emoji}, "\x{1F600}", "Decoded emoji matches character literal \\x{1F600}");
}

# 1.2 Multiple surrogate pairs in sequence (U+1F600 and U+1F602: \uD83D\uDE00\uD83D\uDE02)
{
    my $json = q(["\uD83D\uDE00\uD83D\uDE02"]);
    my $data = MiniJSON::decode($json);
    is(length($data->[0]), 2, "Decoded two surrogate pairs has length 2");
    is($data->[0], "\x{1F600}\x{1F602}", "Decoded pairs match \\x{1F600}\\x{1F602}");
}

# 1.3 Surrogate pair mixed with ASCII and BMP escapes
{
    my $json = q({"text":"Hello \uD83D\uDE00 world \u20AC!"});
    my $data = MiniJSON::decode($json);
    is($data->{text}, "Hello \x{1F600} world \x{20AC}!", "Decoded surrogate mixed with ASCII and BMP escape");
}

# 1.4 Musical Symbol G Clef (U+1D11E: \uD834\uDD1E)
{
    my $json = q({"clef":"\uD834\uDD1E"});
    my $data = MiniJSON::decode($json);
    is(ord($data->{clef}), 0x1D11E, "Decoded G Clef has codepoint 0x1D11E");
}

# 1.5 Isolated high surrogate does not die and produces replacement character U+FFFD
{
    my $json1 = q({"isolated_high":"\uD83D"});
    my $data1 = eval { MiniJSON::decode($json1) };
    ok(!$@, "Isolated high surrogate at end of string does not die") or diag("Died: $@");
    is($data1->{isolated_high}, "\x{FFFD}", "Isolated high surrogate produces U+FFFD replacement char");

    my $json2 = q({"isolated_high_mid":"\uD83D hello"});
    my $data2 = eval { MiniJSON::decode($json2) };
    ok(!$@, "Isolated high surrogate followed by text does not die");
    is($data2->{isolated_high_mid}, "\x{FFFD} hello", "Isolated high surrogate followed by text has U+FFFD");

    my $json3 = q({"two_high":"\uD83D\uD83D\uDE00"});
    my $data3 = eval { MiniJSON::decode($json3) };
    ok(!$@, "High surrogate followed by valid surrogate pair does not die");
    is($data3->{two_high}, "\x{FFFD}\x{1F600}", "First high is U+FFFD, second pair decodes to emoji");
}

# 1.6 Isolated low surrogate does not die and produces replacement character U+FFFD
{
    my $json1 = q({"isolated_low":"\uDE00"});
    my $data1 = eval { MiniJSON::decode($json1) };
    ok(!$@, "Isolated low surrogate does not die");
    is($data1->{isolated_low}, "\x{FFFD}", "Isolated low surrogate produces U+FFFD");

    my $json2 = q({"isolated_low_mid":"\uDE00\uD83D\uDE00"});
    my $data2 = eval { MiniJSON::decode($json2) };
    ok(!$@, "Isolated low surrogate followed by valid pair does not die");
    is($data2->{isolated_low_mid}, "\x{FFFD}\x{1F600}", "Isolated low is U+FFFD followed by valid emoji");
}

# 1.7 Malformed \\u escape (non-hex digits) dies with JSON parse error
{
    my $json = q({"bad":"\u123z"});
    my $res = eval { MiniJSON::decode($json) };
    ok($@, "Malformed \\u escape throws parse error");
    like($@, qr/JSON parse error/i, "Error message mentions JSON parse error");
}

# ---------------------------------------------------------------------------
# Group 2: Line Endings & Whitespace
# ---------------------------------------------------------------------------

# 2.1 Windows line endings (CRLF \r\n) in whitespace
{
    my $json = "{\r\n  \"name\": \"test\",\r\n  \"value\": 123\r\n}";
    my $data = MiniJSON::decode($json);
    is_deeply($data, { name => 'test', value => 123 }, "Parsed CRLF whitespace JSON");
}

# 2.2 Classic Mac OS 9 line endings (CR \r) in whitespace
{
    my $json = "{\r  \"items\": [\r    1,\r    2\r  ]\r}";
    my $data = MiniJSON::decode($json);
    is_deeply($data, { items => [ 1, 2 ] }, "Parsed CR-only whitespace JSON");
}

# 2.3 Unix line endings (LF \n) in whitespace
{
    my $json = "{\n  \"ok\": true\n}";
    my $data = MiniJSON::decode($json);
    is_deeply($data, { ok => 1 }, "Parsed LF whitespace JSON");
}

# 2.4 Mixed line endings and surrounding whitespace
{
    my $json = "  \r\n\t {\r \"a\": \n 1,\r\n \"b\":\t2 } \t\r\n ";
    my $data = MiniJSON::decode($json);
    is_deeply($data, { a => 1, b => 2 }, "Parsed mixed line endings and surrounding whitespace");
}

# ---------------------------------------------------------------------------
# Group 3: Escaped Characters
# ---------------------------------------------------------------------------

# 3.1 Standard JSON escape sequences
{
    my $json = '{"escapes":"quote:\" backslash:\\\\ slash:\\/ bell:\\b ff:\\f nl:\\n cr:\\r tab:\\t"}';
    my $data = MiniJSON::decode($json);
    my $expected = "quote:\" backslash:\\ slash:/ bell:\b ff:\f nl:\n cr:\r tab:\t";
    is($data->{escapes}, $expected, "All standard escape sequences decoded correctly");
}

# 3.2 BMP \\uXXXX escapes
{
    my $json = q({"bmp":"\u0041\u0042\u0043 \u00e9 \u20AC"});
    my $data = MiniJSON::decode($json);
    is($data->{bmp}, "ABC \x{00e9} \x{20AC}", "Decoded ASCII and BMP Unicode escapes");
}

# 3.3 Unterminated string error
{
    my $json = q({"unterminated": "abc});
    my $res = eval { MiniJSON::decode($json) };
    ok($@, "Unterminated string throws error");
    like($@, qr/unterminated/i, "Error message mentions unterminated");
}

# 3.4 Escape sequence at end of string without character
{
    my $json = qq({"escape_at_end": "abc\\);
    my $res = eval { MiniJSON::decode($json) };
    ok($@, "Trailing backslash at end of string throws error");
}

# ---------------------------------------------------------------------------
# Group 4: Empty Structures & Empty Payloads
# ---------------------------------------------------------------------------

# 4.1 Empty object and empty array
{
    my $data1 = MiniJSON::decode("{}");
    is_deeply($data1, {}, "Decoded empty object {}");

    my $data2 = MiniJSON::decode("[]");
    is_deeply($data2, [], "Decoded empty array []");

    my $data3 = MiniJSON::decode("{\n\r\t }");
    is_deeply($data3, {}, "Decoded empty object with whitespace");

    my $data4 = MiniJSON::decode("[\r\n\t ]");
    is_deeply($data4, [], "Decoded empty array with whitespace");
}

# 4.2 Empty string and empty keys
{
    my $json = q({"":"","key":""});
    my $data = MiniJSON::decode($json);
    is_deeply($data, { "" => "", "key" => "" }, "Decoded empty key and empty string values");
}

# 4.3 Nested empty structures
{
    my $json = q({"obj":{},"arr":[],"str":""});
    my $data = MiniJSON::decode($json);
    is_deeply($data, { obj => {}, arr => [], str => "" }, "Decoded nested empty structures");
}

# 4.4 Empty or undef input throws error
{
    my $res1 = eval { MiniJSON::decode("") };
    ok($@, "Empty string input throws error");

    my $res2 = eval { MiniJSON::decode("   \r\n\t ") };
    ok($@, "Whitespace-only input throws error");

    my $res3 = eval { MiniJSON::decode(undef) };
    ok($@, "Undef input throws error");
}

# ---------------------------------------------------------------------------
# Group 5: Numbers, Booleans, Nulls
# ---------------------------------------------------------------------------

# 5.1 Numbers (integers, negative, decimals, exponents)
{
    my $json = q([0, -0, 42, -999, 3.14159, -0.05, 1e6, 2.5E-3, -1.2e+4]);
    my $data = MiniJSON::decode($json);
    is($data->[0], 0, "Integer 0");
    is($data->[1], 0, "Integer -0");
    is($data->[2], 42, "Integer 42");
    is($data->[3], -999, "Negative integer -999");
    ok(abs($data->[4] - 3.14159) < 0.00001, "Float 3.14159");
    ok(abs($data->[5] - (-0.05)) < 0.00001, "Negative float -0.05");
    is($data->[6], 1000000, "Exponent 1e6");
    ok(abs($data->[7] - 0.0025) < 0.00001, "Exponent 2.5E-3");
    is($data->[8], -12000, "Exponent -1.2e+4");
}

# 5.2 Booleans and null
{
    my $json = q({"t":true,"f":false,"n":null});
    my $data = MiniJSON::decode($json);
    is($data->{t}, 1, "Boolean true decoded to 1");
    is($data->{f}, 0, "Boolean false decoded to 0");
    ok(!defined $data->{n}, "Null decoded to undef");
}

# 5.3 Bareword unrecognized token dies
{
    my $json = q([trueness]);
    my $res = eval { MiniJSON::decode($json) };
    ok($@, "Invalid bareword token throws parse error");
}

# ---------------------------------------------------------------------------
# Group 6: Deeply Nested Structures (Recursion Safety)
# ---------------------------------------------------------------------------

# 6.1 Deeply nested array (150 levels)
{
    my $depth = 150;
    my $json = ("[" x $depth) . "42" . ("]" x $depth);
    my $data = eval { MiniJSON::decode($json) };
    ok(!$@, "Decoded 150 levels deep array without error") or diag("Died: $@");
    my $curr = $data;
    for (1 .. $depth - 1) {
        $curr = $curr->[0];
    }
    is($curr->[0], 42, "Deepest value in 150-level array is 42");

    # Test encoding deeply nested array
    my $encoded = eval { MiniJSON::encode($data) };
    ok(!$@, "Encoded 150 levels deep array without error");
}

# 6.2 Deeply nested object (150 levels)
{
    my $depth = 150;
    my $json = ("{\"a\":" x $depth) . "99" . ("}" x $depth);
    my $data = eval { MiniJSON::decode($json) };
    ok(!$@, "Decoded 150 levels deep object without error");
    my $curr = $data;
    for (1 .. $depth - 1) {
        $curr = $curr->{a};
    }
    is($curr->{a}, 99, "Deepest value in 150-level object is 99");

    # Test encoding deeply nested object
    my $encoded = eval { MiniJSON::encode($data) };
    ok(!$@, "Encoded 150 levels deep object without error");
}

# ---------------------------------------------------------------------------
# Group 7: Encoder Behaviors & Roundtrip
# ---------------------------------------------------------------------------

# 7.1 Complex roundtrip
{
    my $payload = {
        name    => "Agent Tiger",
        version => "1.0",
        active  => \1,
        debug   => \0,
        empty   => undef,
        counts  => [ 0, 10, -5, 3.14 ],
        nested  => {
            greeting => "Hello \x{1F600}!",
            symbols  => "\x{20AC} \x{2603}",
        },
    };
    my $json = MiniJSON::encode($payload);
    my $decoded = MiniJSON::decode($json);

    is($decoded->{name}, "Agent Tiger", "Roundtrip string");
    is($decoded->{version}, "1.0", "Preserved string literal for version");
    is($decoded->{active}, 1, "Roundtrip boolean true");
    is($decoded->{debug}, 0, "Roundtrip boolean false");
    ok(!defined $decoded->{empty}, "Roundtrip null");
    is_deeply($decoded->{counts}, [ 0, 10, -5, 3.14 ], "Roundtrip numbers array");
    is($decoded->{nested}{greeting}, "Hello \x{1F600}!", "Roundtrip emoji text");
    is($decoded->{nested}{symbols}, "\x{20AC} \x{2603}", "Roundtrip BMP unicode symbols");
}

# 7.2 encode_string safety with undef and control characters
{
    is(MiniJSON::encode_string(undef), '""', "encode_string(undef) returns empty quoted string without warning");
    my $ctrl = "line1\nline2\rline3\ttab\x00null\x1funit";
    my $enc = MiniJSON::encode_string($ctrl);
    like($enc, qr/\\n/, "Newlines escaped");
    like($enc, qr/\\r/, "CR escaped");
    like($enc, qr/\\t/, "Tab escaped");
    like($enc, qr/\\u0000/, "Null byte escaped as \\u0000");
    like($enc, qr/\\u001f/, "Control char 0x1f escaped as \\u001f");

    my $dec = MiniJSON::decode($enc);
    is($dec, $ctrl, "Control character roundtrip matches original exactly");
}

done_testing();
