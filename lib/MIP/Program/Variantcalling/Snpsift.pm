package MIP::Program::Variantcalling::Snpsift;

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
use autodie qw{ :all };
use Readonly;

## MIPs lib/
use MIP::Unix::Standard_streams qw{ unix_standard_streams };
use MIP::Unix::Write_to_file qw{ unix_write_to_file };

BEGIN {
    require Exporter;
    use base qw{ Exporter };

    # Set the version for version checking
    our $VERSION = 1.00;

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw{ snpsift_annotate snpsift_dbnsfp };
}

## Constants
Readonly my $COMMA => q{,};
Readonly my $DASH  => q{-};
Readonly my $SPACE => q{ };

sub snpsift_annotate {

## Function : Perl wrapper for writing snpsift ann recipe to already open $FILEHANDLE or return commands array. Based on Snpsift 4.2 (build 2015-12-05).
## Returns  : @commands
## Arguments: $config_file_path       => Config file path
##          : $database_path          => Database path
##          : $FILEHANDLE             => Filehandle to write to
##          : $infile_path            => Infile path
##          : $info                   => Annotate using a list of info fields (list is a comma separated list of fields)
##          : $name_prefix            => Prepend 'str' to all annotated INFO fields
##          : $stderrfile_path        => Stderrfile path
##          : $stderrfile_path_append => Append stderr info to file path
##          : $stdoutfile_path        => Stdoutfile path
##          : $verbosity              => Increase output verbosity

    my ($arg_href) = @_;

    ## Flatten argument(s)
    my $config_file_path;
    my $database_path;
    my $FILEHANDLE;
    my $infile_path;
    my $info;
    my $name_prefix;
    my $stderrfile_path;
    my $stderrfile_path_append;
    my $stdoutfile_path;
    my $verbosity;

    my $tmpl = {
        config_file_path => { strict_type => 1, store => \$config_file_path },
        database_path    => {
            required    => 1,
            defined     => 1,
            strict_type => 1,
            store       => \$database_path,
        },
        FILEHANDLE => {
            store => \$FILEHANDLE,
        },
        infile_path     => { strict_type => 1, store => \$infile_path, },
        info            => { strict_type => 1, store => \$info, },
        name_prefix     => { strict_type => 1, store => \$name_prefix, },
        stderrfile_path => {
            strict_type => 1,
            store       => \$stderrfile_path,
        },
        stderrfile_path_append => {
            strict_type => 1,
            store       => \$stderrfile_path_append,
        },
        stdoutfile_path => {
            strict_type => 1,
            store       => \$stdoutfile_path,
        },
        verbosity => {
            allow       => qr/^\w+$/,
            strict_type => 1,
            store       => \$verbosity,
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak q{Could not parse arguments!};

    ## Stores commands depending on input parameters
    my @commands = q{annotate};

    ## Options
    if ($verbosity) {

        push @commands, q{-} . $verbosity;
    }

    if ($config_file_path) {

        push @commands, q{-config} . $SPACE . $config_file_path;
    }

    if ($name_prefix) {

        push @commands, q{-name} . $SPACE . $name_prefix;
    }

    if ($info) {

        push @commands, q{-info} . $SPACE . $info;
    }

    if ($database_path) {

        push @commands, $database_path;
    }

    ## Infile
    if ($infile_path) {

        push @commands, $infile_path;
    }

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
            FILEHANDLE   => $FILEHANDLE,
            commands_ref => \@commands,
            separator    => $SPACE,

        }
    );
    return @commands;
}

sub snpsift_dbnsfp {

## Function : Perl wrapper for writing snpsift dbnsfp recipe to already open $FILEHANDLE or return commands array. Based on Snpsift 4.2 (build 2015-12-05).
## Returns  : @commands
## Arguments: $annotate_fields_ref    => Add annotations for list of fields
##          : $config_file_path       => Config file path
##          : $database_path          => Database path
##          : $FILEHANDLE             => Filehandle to write to
##          : $infile_path            => Infile path
##          : $stderrfile_path        => Stderrfile path
##          : $stderrfile_path_append => Append stderr info to file path
##          : $stdoutfile_path        => Stdoutfile path
##          : $verbosity              => Increase output verbosity

    my ($arg_href) = @_;

    ## Flatten argument(s)
    my $annotate_fields_ref;
    my $config_file_path;
    my $database_path;
    my $FILEHANDLE;
    my $infile_path;
    my $stderrfile_path;
    my $stderrfile_path_append;
    my $stdoutfile_path;
    my $verbosity;

    my $tmpl = {
        annotate_fields_ref => {
            required    => 1,
            defined     => 1,
            default     => [],
            strict_type => 1,
            store       => \$annotate_fields_ref
        },
        config_file_path => { strict_type => 1, store => \$config_file_path },
        database_path    => {
            required    => 1,
            defined     => 1,
            strict_type => 1,
            store       => \$database_path
        },
        FILEHANDLE => {
            store => \$FILEHANDLE,
        },
        infile_path     => { strict_type => 1, store => \$infile_path },
        stderrfile_path => {
            strict_type => 1,
            store       => \$stderrfile_path,
        },
        stderrfile_path_append => {
            strict_type => 1,
            store       => \$stderrfile_path_append,
        },
        stdoutfile_path => {
            strict_type => 1,
            store       => \$stdoutfile_path,
        },
        verbosity => {
            allow       => qr/^\w+$/,
            strict_type => 1,
            store       => \$verbosity
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak q{Could not parse arguments!};

    ## Stores commands depending on input parameters
    my @commands = q{dbnsfp};

    ## Options
    if ($verbosity) {

        push @commands, q{-} . $verbosity;
    }

    if ($config_file_path) {

        push @commands, q{-config} . $SPACE . $config_file_path;
    }

    if ($database_path) {

        push @commands, q{-db} . $SPACE . $database_path;
    }

    if ( @{$annotate_fields_ref} ) {

        push @commands, q{-f} . $SPACE . join $COMMA, @{$annotate_fields_ref};
    }

    ## Infile
    if ($infile_path) {

        push @commands, $infile_path;
    }

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
            FILEHANDLE   => $FILEHANDLE,
            commands_ref => \@commands,
            separator    => $SPACE,

        }
    );
    return @commands;
}

1;
