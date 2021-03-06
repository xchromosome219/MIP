package MIP::Recipes::Analysis::Fastqc;

use Carp;
use charnames qw{ :full :short };
use English qw{ -no_match_vars };
use File::Basename qw(fileparse);
use File::Spec::Functions qw{ catdir catfile };
use open qw{ :encoding(UTF-8) :std };
use Params::Check qw{ allow check last_error };
use strict;
use utf8;
use warnings;
use warnings qw{ FATAL utf8 };

## CPANM
use autodie qw{:all};
use Readonly;

BEGIN {

    require Exporter;
    use base qw{Exporter};

    # Set the version for version checking
    our $VERSION = 1.03;

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw(analysis_fastqc);

}

## Constants
Readonly my $NEWLINE    => qq{\n};
Readonly my $UNDERSCORE => q{_};

sub analysis_fastqc {

## Function : Raw sequence quality analysis using FASTQC.
## Returns  :
## Arguments: $active_parameter_href   => Active parameters for this analysis hash {REF}
##          : $infiles_ref             => Infiles {REF}
##          : $infile_lane_prefix_href => Infile(s) without the ".ending" {REF}
##          : $insample_directory      => In sample directory
##          : $job_id_href             => Job id hash {REF}
##          : $outsample_directory     => Out sample directory
##          : $parameter_href          => Parameter hash {REF}
##          : $program_name            => Program name
##          : $sample_id               => Sample id
##          : $sample_info_href        => Info on samples and family hash {REF}
##          : $temp_directory          => Temporary directory

    my ($arg_href) = @_;

    ## Flatten argument(s)
    my $active_parameter_href;
    my $infiles_ref;
    my $infile_lane_prefix_href;
    my $insample_directory;
    my $job_id_href;
    my $outsample_directory;
    my $parameter_href;
    my $program_name;
    my $sample_id;
    my $sample_info_href;

    ## Default(s)
    my $temp_directory;

    my $tmpl = {
        active_parameter_href => {
            default     => {},
            defined     => 1,
            required    => 1,
            store       => \$active_parameter_href,
            strict_type => 1,
        },
        infiles_ref => {
            default     => [],
            defined     => 1,
            store       => \$infiles_ref,
            strict_type => 1,
        },
        infile_lane_prefix_href => {
            default     => {},
            defined     => 1,
            required    => 1,
            store       => \$infile_lane_prefix_href,
            strict_type => 1,
        },
        insample_directory => {
            defined     => 1,
            required    => 1,
            store       => \$insample_directory,
            strict_type => 1,
        },
        job_id_href => {
            default     => {},
            defined     => 1,
            required    => 1,
            store       => \$job_id_href,
            strict_type => 1,
        },
        outsample_directory => {
            defined     => 1,
            required    => 1,
            store       => \$outsample_directory,
            strict_type => 1,
        },
        parameter_href => {
            default     => {},
            defined     => 1,
            required    => 1,
            store       => \$parameter_href,
            strict_type => 1,
        },
        program_name => {
            defined     => 1,
            required    => 1,
            store       => \$program_name,
            strict_type => 1,
        },
        sample_id => {
            defined     => 1,
            required    => 1,
            store       => \$sample_id,
            strict_type => 1,
        },
        sample_info_href => {
            default     => {},
            defined     => 1,
            required    => 1,
            store       => \$sample_info_href,
            strict_type => 1,
        },
        temp_directory => {
            default     => $arg_href->{active_parameter_href}{temp_directory},
            store       => \$temp_directory,
            strict_type => 1,
        },
    };

    check( $tmpl, $arg_href, 1 ) or croak qw{Could not parse arguments!};

    use MIP::Check::Cluster qw{check_max_core_number};
    use MIP::Cluster qw{update_core_number_to_seq_mode};
    use MIP::Get::Parameter qw{ get_module_parameters };
    use MIP::Gnu::Coreutils qw{gnu_cp};
    use MIP::IO::Files qw{migrate_files};
    use MIP::Processmanagement::Processes qw{print_wait};
    use MIP::Processmanagement::Slurm_processes
      qw{slurm_submit_job_no_dependency_dead_end};
    use MIP::Program::Qc::Fastqc qw{fastqc};
    use MIP::QC::Record qw{add_program_outfile_to_sample_info};
    use MIP::Script::Setup_script qw{setup_script};

    ## Retrieve logger object
    my $log = Log::Log4perl->get_logger(q{MIP});

    my $mip_program_name = q{p} . $program_name;
    my $mip_program_mode = $active_parameter_href->{$mip_program_name};

    my ( $core_number, $time, $source_environment_cmd ) = get_module_parameters(
        {
            active_parameter_href => $active_parameter_href,
            mip_program_name      => $mip_program_name,
        }
    );

    ## Filehandles
    # Create anonymous filehandle
    my $FILEHANDLE = IO::Handle->new();

  INFILE_LANE:
    foreach my $infile ( @{ $infile_lane_prefix_href->{$sample_id} } ) {

        ## Update the number of cores to be used in the analysis according to sequencing mode requirements
        $core_number = update_core_number_to_seq_mode(
            {
                core_number => $core_number,
                sequence_run_type =>
                  $sample_info_href->{sample}{$sample_id}{file}{$infile}
                  {sequence_run_type},
            }
        );
    }

    ## Limit number of cores requested to the maximum number of cores available per node
    $core_number = check_max_core_number(
        {
            core_number_requested => $core_number,
            max_cores_per_node => $active_parameter_href->{max_cores_per_node},
        }
    );

    ## Creates program directories (info & programData & programScript), program script filenames and writes sbatch header
    my ($file_name) = setup_script(
        {
            active_parameter_href           => $active_parameter_href,
            core_number                     => $core_number,
            directory_id                    => $sample_id,
            FILEHANDLE                      => $FILEHANDLE,
            job_id_href                     => $job_id_href,
            process_time                    => $time,
            program_directory               => $program_name,
            program_name                    => $program_name,
            source_environment_commands_ref => [$source_environment_cmd],
            temp_directory                  => $temp_directory,
        }
    );

    ## Assign suffix
    my $infile_suffix = $parameter_href->{$mip_program_name}{infile_suffix};

    ## Copies files from source to destination
    migrate_files(
        {
            core_number  => $core_number,
            FILEHANDLE   => $FILEHANDLE,
            indirectory  => $insample_directory,
            infiles_ref  => \@{$infiles_ref},
            outfile_path => $temp_directory,
        }
    );

    say {$FILEHANDLE} q{## } . $program_name;

    my $process_batches_count = 1;

    while ( my ( $index, $infile ) = each @{$infiles_ref} ) {

        $process_batches_count = print_wait(
            {
                FILEHANDLE            => $FILEHANDLE,
                max_process_number    => $core_number,
                process_batches_count => $process_batches_count,
                process_counter       => $index,
            }
        );

        ## Removes ".file_ending" in filename.FILENDING(.gz)
        my $file_at_lane_level =
          fileparse( $infile, qr/$infile_suffix|$infile_suffix[.]gz/sxm );

        fastqc(
            {
                extract           => 1,
                FILEHANDLE        => $FILEHANDLE,
                infile_path       => catfile( $temp_directory, $infile ),
                outdirectory_path => $temp_directory,
            }
        );
        say {$FILEHANDLE} q{&}, $NEWLINE;

        ## Collect QC metadata info for active program for later use
        if ( $mip_program_mode == 1 ) {

            my $qc_fastqc_outdirectory =
              catdir( $outsample_directory,
                $file_at_lane_level . $UNDERSCORE . $program_name );
            add_program_outfile_to_sample_info(
                {
                    infile       => $infile,
                    outdirectory => $qc_fastqc_outdirectory,
                    outfile      => q{fastqc_data.txt},
                    path =>
                      catfile( $qc_fastqc_outdirectory, q{fastqc_data.txt} ),
                    program_name     => $program_name,
                    sample_id        => $sample_id,
                    sample_info_href => $sample_info_href,
                }
            );
        }
    }
    say {$FILEHANDLE} q{wait}, $NEWLINE;

    ## Copies files from temporary folder to source.
    $process_batches_count = 1;
    while ( my ( $index, $infile ) = each @{$infiles_ref} ) {

        $process_batches_count = print_wait(
            {
                FILEHANDLE            => $FILEHANDLE,
                max_process_number    => $core_number,
                process_batches_count => $process_batches_count,
                process_counter       => $index,
            }
        );

        ## Removes ".file_ending" in filename.FILENDING(.gz)
        my $file_at_lane_level =
          fileparse( $infile, qr/$infile_suffix|$infile_suffix[.]gz/sxm );

        my $infile_path = catfile( $temp_directory,
            $file_at_lane_level . $UNDERSCORE . $program_name );
        gnu_cp(
            {
                FILEHANDLE   => $FILEHANDLE,
                infile_path  => $infile_path,
                outfile_path => $outsample_directory,
                recursive    => 1,
            }
        );
        say {$FILEHANDLE} q{&}, $NEWLINE;
    }
    say {$FILEHANDLE} q{wait}, $NEWLINE;

    close $FILEHANDLE;

    if ( $mip_program_mode == 1 ) {

        slurm_submit_job_no_dependency_dead_end(
            {
                job_id_href      => $job_id_href,
                log              => $log,
                sbatch_file_name => $file_name,
            }
        );
    }
    return;
}

1;
