#! /usr/bin/perl -w
# File:		modules/Json.pm
# Package:	yast2-crowbar
# Summary:	Module for parsing JSON file
# Author:	Jiri Suchomel <jsuchome@suse.cz>

package Json;

use strict;
use YaST::YCP qw(:LOGGING);
use JSON;
use Data::Dumper;

our %TYPEINFO;

YaST::YCP::Import ("SCR");

# --------------------------------------- main -----------------------------

# adapt JSON and Perl value types to YCP ones, so we can distinguish
# integers and booleans
sub adapt_value4ycp {

    my $value	= shift;

    if (ref ($value) eq "HASH") {
      $value  = adapt_hash4ycp ($value);
    }
    elsif (ref ($value) eq "ARRAY") {
      for my $val (@$value) {
        $val  = adapt_value4ycp ($val);
      }
    }
    elsif (JSON::is_bool ($value)) {
      $value = YaST::YCP::Boolean ($value);
    }
    elsif ($value =~ /^[+-]?\d+$/ ) {
      $value = YaST::YCP::Integer ($value);
    }
    return $value;
}

sub adapt_hash4ycp {

    my $hash	= shift;
    for my $value (values %$hash) {
      $value    = adapt_value4ycp ($value);
    }
    return $hash;
}

# adapt YCP values back to Perl or JSON ones
sub adapt_value4json {

    my $value	= shift;

    if (ref ($value) eq "HASH") {
      $value  = adapt_hash4json ($value);
    }
    elsif (ref ($value) eq "ARRAY") {
      for my $val (@$value) {
        $val  = adapt_value4json ($val);
      }
    }
    elsif ($value eq "true" || $value eq "false") {
      $value  = $value eq "true" ? JSON::true : JSON::false;
    }
    elsif ($value =~ /^[+-]?\d+$/ ) {
      $value = $value + 0;
    }
    return $value;
}


sub adapt_hash4json {

    my $hash	= shift;
    for my $value (values %$hash) {
      $value    = adapt_value4json ($value);
    }
    return $hash;
}

# read content of JSON file; argument is file path
BEGIN { $TYPEINFO{Read} = ["function",
  ["map", "string", "any"],
  "string" ]
}
sub Read {

    my $self	= shift;
    my $file	= shift;
    my $ret	= {};

    local $/=undef;
    open FILE, $file or do {
      y2error ("Couldn't open file '$file' for reading");
      return undef;
    };
    my $file_content = <FILE>;
    close FILE;

    my $result = decode_json ($file_content);

    return adapt_hash4ycp ($result);
}

# write the file contents;  1st argument data hash, 2nd is file path
BEGIN { $TYPEINFO{Write} = ["function",
    "boolean",
    ["map", "string", "any"], "string"]
}
sub Write {

    my $self	= shift;
    my $contents= shift;
    my $file	= shift;

    $contents   = adapt_hash4json ($contents);

    open (FILE, '>', $file) or do {
      y2error ("Couldn't open file '$file' for writing");
      return 0;
    };
    print FILE JSON->new->utf8->pretty(1)->encode($contents);
    close FILE; 

    return 1;
}
42
# end
