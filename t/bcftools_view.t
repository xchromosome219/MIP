#!/usr/bin/env perl

use Carp;
use charnames qw{ :full :short };
use English qw{ -no_match_vars };
use File::Basename qw{ dirname basename };
use File::Spec::Functions qw{ catdir };
use FindBin qw{ $Bin };
use Getopt::Long;
use open qw{ :encoding(UTF-8) :std };
use Params::Check qw{ check allow last_error };
use Test::More;
use utf8;
use warnings qw{ FATAL utf8 };
use 5.018;

## CPANM
use Modern::Perl qw{ 2014 };
use autodie;
use Readonly;

## MIPs lib/
use lib catdir( dirname($Bin), q{lib} );
use MIP::Script::Utils qw{ help };

our $USAGE = build_usage( {} );

my $VERBOSE = 1;
our $VERSION = 1.0.1;

## Constants
Readonly my $COMMA   => q{,};
Readonly my $NEWLINE => qq{\n};
Readonly my $SPACE   => q{ };

### User Options
GetOptions(

    # Display help text
    q{h|help} => sub {
        done_testing();
        say {*STDOUT} $USAGE;
        exit;
    },

    # Display version number
    q{v|version} => sub {
        done_testing();
        say {*STDOUT} $NEWLINE
          . basename($PROGRAM_NAME)
          . $SPACE
          . $VERSION
          . $NEWLINE;
        exit;
    },
    q{vb|verbose} => $VERBOSE,
  )
  or (
    done_testing(),
    help(
        {
            USAGE     => $USAGE,
            exit_code => 1,
        }
    )
  );

BEGIN {

### Check all internal dependency modules and imports
## Modules with import
    my %perl_module = ( q{MIP::Script::Utils} => [qw{ help }], );

  PERL_MODULE:
    while ( my ( $module, $module_import ) = each %perl_module ) {
        use_ok( $module, @{$module_import} )
          or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }

## Modules
    my @modules = (q{MIP::Program::Variantcalling::Bcftools});

  MODULE:
    for my $module (@modules) {
        require_ok($module) or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }
}

use MIP::Program::Variantcalling::Bcftools qw{ bcftools_view };
use MIP::Test::Commands qw{ test_function };

diag(   q{Test bcftools_view from Bcftools.pm v}
      . $MIP::Program::Variantcalling::Bcftools::VERSION
      . $COMMA
      . $SPACE . q{Perl}
      . $SPACE
      . $PERL_VERSION
      . $SPACE
      . $EXECUTABLE_NAME );

## Base arguments
my $function_base_command = q{bcftools};

my %base_argument = (
    FILEHANDLE => {
        input           => undef,
        expected_output => $function_base_command,
    },
    stderrfile_path => {
        input           => q{stderrfile.test},
        expected_output => q{2> stderrfile.test},
    },
    stderrfile_path_append => {
        input           => q{stderrfile.test},
        expected_output => q{2>> stderrfile.test},
    },
    stdoutfile_path => {
        input           => q{stdoutfile.test},
        expected_output => q{1> stdoutfile.test},
    },
);

## Can be duplicated with %base_argument and/or %specific_argument
## to enable testing of each individual argument
my %required_argument = ();

my %specific_argument = (
    apply_filters_ref => {
        inputs_ref      => [qw{ filter1 filter2 }],
        expected_output => q{--apply-filters filter1,filter2},
    },
    exclude_types_ref => {
        inputs_ref      => [qw{ type1 type2 }],
        expected_output => q{--exclude-types type1,type2},
    },
    exclude => {
        input           => q{%QUAL<10 || (RPB<0.1 && %QUAL<15)},
        expected_output => q{--exclude %QUAL<10 || (RPB<0.1 && %QUAL<15)},
    },
    include => {
        input           => q{INFO/CSQ[*]~":p[.]"},
        expected_output => q{--include INFO/CSQ[*]~":p[.]"},
    },
    outfile_path => {
        input           => q{outfile.txt},
        expected_output => q{--output-file outfile.txt},
    },
    infile_path => {
        input           => q{infile.test},
        expected_output => q{infile.test},
    },
    output_type => {
        input           => q{v},
        expected_output => q{--output-type v},
    },

);

## Coderef - enables generalized use of generate call
my $module_function_cref = \&bcftools_view;

## Test both base and function specific arguments
my @arguments = ( \%base_argument, \%specific_argument );

ARGUMENT_HASH_REF:
foreach my $argument_href (@arguments) {
    my @commands = test_function(
        {
            argument_href          => $argument_href,
            required_argument_href => \%required_argument,
            module_function_cref   => $module_function_cref,
            function_base_command  => $function_base_command,
            do_test_base_command   => 1,
        }
    );
}

done_testing();

######################
####SubRoutines#######
######################

sub build_usage {

## build_usage

## Function  : Build the USAGE instructions
## Returns   : ""
## Arguments : $program_name
##           : $program_name => Name of the script

    my ($arg_href) = @_;

    ## Default(s)
    my $program_name;

    my $tmpl = {
        program_name => {
            default     => basename($PROGRAM_NAME),
            strict_type => 1,
            store       => \$program_name,
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak q{Could not parse arguments!};

    return <<"END_USAGE";
 $program_name [options]
    -vb/--verbose Verbose
    -h/--help Display this help message
    -v/--version Display version
END_USAGE
}
