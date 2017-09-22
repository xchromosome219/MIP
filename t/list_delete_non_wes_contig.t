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
use File::Spec::Functions qw{ catdir };
use Getopt::Long;
use Test::More;

## CPANM
use Readonly;

## MIPs lib/
use lib catdir( dirname($Bin), q{lib} );
use Script::Utils qw{ help };

our $USAGE = build_usage( {} );

my $VERBOSE = 1;
our $VERSION = '1.0.0';

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
    Script::Utils::help(
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

    $perl_module{q{Script::Utils}} = [qw{ help }];

  PERL_MODULE:
    while ( my ( $module, $module_import ) = each %perl_module ) {
        use_ok( $module, @{$module_import} )
          or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }

## Modules
    my @modules = (q{MIP::Delete::List});

  MODULE:
    for my $module (@modules) {
        require_ok($module) or BAIL_OUT q{Cannot load} . $SPACE . $module;
    }
}

use MIP::Delete::List qw{ delete_non_wes_contig };

diag(   q{Test delete_non_wes_contig from List.pm v}
      . $MIP::Delete::List::VERSION
      . $COMMA
      . $SPACE . q{Perl}
      . $SPACE
      . $PERL_VERSION
      . $SPACE
      . $EXECUTABLE_NAME );

my %not_consensus_analysis_type = (
    sample_id_1 => q{wes},
    sample_id_2 => q{wgs}
);

my %consensus_analysis_type = (
    sample_id_1 => q{wes},
    sample_id_2 => q{wes}
);

my @refseq_contigs = qw{
  chr1 chr2 chr3 chr4 chr5 chr6
  chr7 chr8 chr9 chr10 chr11 chr12
  chr13 chr14 chr15 chr16 chr17 chr18
  chr19 chr20 chr21 chr22 chrX chrY
  chrM };

my @ensembl_contigs = qw{
  1 2 3 4 5 6 7 8 9 10
  11 12 13 14 15 16 17 18 19 20
  21 22 X Y MT };

## Tests

my @contigs = delete_non_wes_contig(
    {
        analysis_type_href => \%not_consensus_analysis_type,
        contigs_ref        => \@refseq_contigs,
        contig_names_ref   => [qw{ M MT }],
    }
);
is(
    scalar @contigs,
    scalar @refseq_contigs,
    q{Not wes: keept M contig in array}
);

@contigs = delete_non_wes_contig(
    {
        analysis_type_href => \%consensus_analysis_type,
        contigs_ref        => \@refseq_contigs,
        contig_names_ref   => [qw{ M MT }],
    }
);

is(
    scalar @contigs,
    scalar @refseq_contigs - 1,
    q{Wes: Removed M contig in array}
);

@contigs = delete_non_wes_contig(
    {
        analysis_type_href => \%not_consensus_analysis_type,
        contigs_ref        => \@ensembl_contigs,
        contig_names_ref   => [qw{ M MT }],
    }
);
is(
    scalar @contigs,
    scalar @ensembl_contigs,
    q{Not wes: keept MT contig in array}
);

@contigs = delete_non_wes_contig(
    {
        analysis_type_href => \%consensus_analysis_type,
        contigs_ref        => \@ensembl_contigs,
        contig_names_ref   => [qw{ M MT }],
    }
);

is(
    scalar @contigs,
    scalar @ensembl_contigs - 1,
    q{Wes: Removed MT contig in array}
);

done_testing();

######################
####SubRoutines#######
######################

sub build_usage {

## build_usage

## Function  : Build the USAGE instructions
## Returns   : ""
## Arguments : $program_name
##          : $program_name => Name of the script

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
