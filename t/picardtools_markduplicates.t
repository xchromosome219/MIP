#!/usr/bin/env perl

use Modern::Perl qw{ 2014 };
use warnings qw{ FATAL utf8 };
use autodie;
use 5.018;
use utf8;
use open qw{ :encoding(UTF-8) :std };
use charnames qw{ :full :short };
use Carp;
use English qw{ -no_match_vars };
use Params::Check qw{ check allow last_error };

use FindBin qw{ $Bin };
use File::Basename qw{ dirname basename };
use File::Spec::Functions qw{ catdir catfile };
use Getopt::Long;
use Test::More;
use Readonly;

## MIPs lib/
use lib catdir( dirname($Bin), q{lib} );
use MIP::Script::Utils qw{ help };

our $USAGE = build_usage( {} );

my $VERBOSE = 1;
our $VERSION = 1.0.0;

## Constants
Readonly my $SPACE   => q{ };
Readonly my $NEWLINE => qq{\n};
Readonly my $COMMA   => q{,};

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
    my %perl_module;

    $perl_module{q{MIP::Script::Utils}} = [qw{ help }];

  PERL_MODULE:
    while ( my ( $module, $module_import ) = each %perl_module ) {
        use_ok( $module, @{$module_import} )
          or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }

## Modules
    my @modules = (q{MIP::Program::Alignment::Picardtools});

  MODULE:
    for my $module (@modules) {
        require_ok($module) or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }
}

use MIP::Program::Alignment::Picardtools qw{ picardtools_markduplicates };
use MIP::Test::Commands qw{ test_function };

diag(   q{Test picardtools_markduplicates from Picardtools.pm v}
      . $MIP::Program::Alignment::Picardtools::VERSION
      . $COMMA
      . $SPACE . q{Perl}
      . $SPACE
      . $PERL_VERSION
      . $SPACE
      . $EXECUTABLE_NAME );

## Base arguments
my $function_base_command = q{MarkDuplicates};

my %base_argument = (
    FILEHANDLE => {
        input           => undef,
        expected_output => $function_base_command,
    },
);

## Can be duplicated with %base_argument and/or %specific_argument
## to enable testing of each individual argument
my %required_argument = (
    infile_paths_ref => {
        inputs_ref      => [qw{ infile_1 infile_2  }],
        expected_output => q{INPUT=infile_1 INPUT=infile_2},
    },
    outfile_path => {
        input           => catfile(qw{ out_directory outfile }),
        expected_output => q{OUTPUT=} . catfile(qw{ out_directory outfile }),
    },
    metrics_file => {
        input           => q{metric_file},
        expected_output => q{METRICS_FILE=} . q{metric_file},
    },
    referencefile_path => {
        input => catfile(qw{ references GRCh37_homo_sapiens_-d5-.fasta }),
        expected_output => q{R=}
          . catfile(qw{ references GRCh37_homo_sapiens_-d5-.fasta }),
    },
);

my %specific_argument = (
    create_index => {
        input           => q{true},
        expected_output => q{CREATE_INDEX=true},
    },
    infile_paths_ref => {
        inputs_ref      => [qw{ infile_1 infile_2  }],
        expected_output => q{INPUT=infile_1 INPUT=infile_2},
    },
    outfile_path => {
        input           => catfile(qw{ out_directory outfile }),
        expected_output => q{OUTPUT=} . catfile(qw{ out_directory outfile }),
    },
    metrics_file => {
        input           => q{metric_file},
        expected_output => q{METRICS_FILE=} . q{metric_file},
    },
);

## Coderef - enables generalized use of generate call
my $module_function_cref = \&picardtools_markduplicates;

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
