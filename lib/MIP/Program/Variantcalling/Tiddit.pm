package MIP::Program::Variantcalling::Tiddit;

use Carp;
use charnames qw{ :full :short };
use English qw{ -no_match_vars };
use open qw{ :encoding(UTF-8) :std };
use Params::Check qw{ allow check last_error };
use strict;
use utf8;
use warnings;
use warnings qw{ FATAL utf8 };

## CPANM
use Readonly;

## MIPs lib/
use MIP::Unix::Standard_streams qw{ unix_standard_streams };
use MIP::Unix::Write_to_file qw{ unix_write_to_file };

BEGIN {
    require Exporter;
    use base qw{ Exporter };

    # Set the version for version checking
    our $VERSION = 1.02;

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw{ tiddit_coverage tiddit_sv };

}

## Constants
Readonly my $SPACE => q{ };

sub tiddit_coverage {

## Function : Perl wrapper for Tiddit coverage. Based on Tiddit 1.0.2.
## Returns  : @commands
## Arguments: $bin_size               => Bin size
##          : $FILEHANDLE             => Filehandle to write to
##          : $infile_path            => Infile path
##          : $outfile_path_prefix    => Outfile path. Write documents to FILE
##          : $stderrfile_path        => Stderrfile path
##          : $stderrfile_path_append => Append stderr info to file path
##          : $stdoutfile_path        => Stdoutfile path

    my ($arg_href) = @_;

    ## Flatten argument(s)
    my $FILEHANDLE;
    my $infile_path;
    my $outfile_path_prefix;
    my $stderrfile_path;
    my $stderrfile_path_append;
    my $stdoutfile_path;

    ## Default(s)
    my $bin_size;

    my $tmpl = {
        bin_size => {
            allow       => qr/ ^\d+$ /sxm,
            default     => 500,
            store       => \$bin_size,
            strict_type => 1,
        },
        FILEHANDLE => {
            store => \$FILEHANDLE,
        },
        infile_path => {
            defined     => 1,
            required    => 1,
            store       => \$infile_path,
            strict_type => 1,
        },
        outfile_path_prefix =>
          { store => \$outfile_path_prefix, strict_type => 1, },
        stderrfile_path => {
            store       => \$stderrfile_path,
            strict_type => 1,
        },
        stderrfile_path_append => {
            store       => \$stderrfile_path_append,
            strict_type => 1,
        },
        stdoutfile_path => {
            store       => \$stdoutfile_path,
            strict_type => 1,
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak q{Could not parse arguments!};

    ## Stores commands depending on input parameters
    my @commands = q{TIDDIT.py --cov};

    # Option: specify output prefix
    if ($outfile_path_prefix) {

        push @commands, q{-o} . $SPACE . $outfile_path_prefix;
    }

    # Option: specify bin size
    if ($bin_size) {

        push @commands, q{-z} . $SPACE . $bin_size;
    }

    # Specify infile
    push @commands, q{--bam} . $SPACE . $infile_path;

    push @commands,
      unix_standard_streams(
        {
            stderrfile_path        => $stderrfile_path,
            stderrfile_path_append => $stderrfile_path_append,
            stdoutfile_path        => $stdoutfile_path,
        }
      );

    unix_write_to_file(
        {
            commands_ref => \@commands,
            FILEHANDLE   => $FILEHANDLE,
            separator    => $SPACE,

        }
    );
    return @commands;
}

sub tiddit_sv {

## Function : Perl wrapper for writing tiddit sv recipe to $FILEHANDLE or return commands array. Based on tiddit 1.0.2.
## Returns  : @commands
## Arguments: $FILEHANDLE                      => Filehandle to write to
##          : $infile_path                     => Infile path
##          : $minimum_number_supporting_pairs => Minimum number of supporting pairs in order to call a variation event
##          : $outfile_path_prefix             => Outfile path. Write documents to FILE
##          : $referencefile_path              => Genome reference file
##          : $stderrfile_path                 => Stderrfile path
##          : $stderrfile_path_append          => Append stderr info to file path
##          : $stdoutfile_path                 => Stdoutfile path

    my ($arg_href) = @_;

    ## Flatten argument(s)
    my $FILEHANDLE;
    my $infile_path;
    my $minimum_number_supporting_pairs;
    my $outfile_path_prefix;
    my $referencefile_path;
    my $stderrfile_path;
    my $stderrfile_path_append;
    my $stdoutfile_path;

    my $tmpl = {
        FILEHANDLE  => { store => \$FILEHANDLE },
        infile_path => {
            defined     => 1,
            required    => 1,
            store       => \$infile_path,
            strict_type => 1,
        },
        minimum_number_supporting_pairs => {
            allow       => qr/ ^\d+$ /sxm,
            store       => \$minimum_number_supporting_pairs,
            strict_type => 1,
        },
        outfile_path_prefix =>
          { store => \$outfile_path_prefix, strict_type => 1, },
        referencefile_path => {
            defined     => 1,
            required    => 1,
            store       => \$referencefile_path,
            strict_type => 1,
        },
        stderrfile_path => {
            store       => \$stderrfile_path,
            strict_type => 1,
        },
        stderrfile_path_append => {
            store       => \$stderrfile_path_append,
            strict_type => 1,
        },
        stdoutfile_path => {
            store       => \$stdoutfile_path,
            strict_type => 1,
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak q{Could not parse arguments!};

    ## tiddit
    my @commands = qw{ TIDDIT.py --sv };

    ## Option: minimum number of supporting pairs in order to call a variation event
    if ($minimum_number_supporting_pairs) {

        push @commands, q{-p} . $SPACE . $minimum_number_supporting_pairs;
    }

    # Outfile prefix
    if ($outfile_path_prefix) {

        push @commands, q{-o} . $SPACE . $outfile_path_prefix;
    }

    push @commands, q{--ref} . $SPACE . $referencefile_path;

    ## Infile
    push @commands, q{--bam} . $SPACE . $infile_path;

    push @commands,
      unix_standard_streams(
        {
            stderrfile_path        => $stderrfile_path,
            stderrfile_path_append => $stderrfile_path_append,
            stdoutfile_path        => $stdoutfile_path,
        }
      );

    push @commands,
      unix_write_to_file(
        {
            commands_ref => \@commands,
            FILEHANDLE   => $FILEHANDLE,
            separator    => $SPACE,
        }
      );
    return @commands;
}

1;
