#cd /mnt/vde/210/GTEX_goat/RNA/merge/stringtie_merged/quant_merged
#cut -f2 sample_list.txt > result_dirs.list

#TPM: perl ./stringtie_expression_matrix.v2.pl --expression_metric=TPM --result_dirs_file=result_dirs.list --transcript_matrix_file=transcript_tpms_all_samples.tsv --gene_matrix_file=gene_tpms_all_samples.tsv

#FPKM: perl ./stringtie_expression_matrix.v2.pl --expression_metric=TPM --result_dirs_file=result_dirs.list --transcript_matrix_file=transcript_tpms_all_samples.tsv --gene_matrix_file=gene_tpms_all_samples.tsv

#coverage: perl ./stringtie_expression_matrix.v2.pl --expression_metric=coverage --result_dirs_file=result_dirs.list --transcript_matrix_file=transcript_coverage_all_samples.tsv --gene_matrix_file=gene_coverage_all_samples.tsv








#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use IO::File;

my $expression_metric = '';
my $result_dirs = '';
my $result_dirs_file = '';
my $transcript_matrix_file = '';
my $gene_matrix_file = '';

GetOptions(
    'expression_metric=s'      => \$expression_metric,
    'result_dirs=s'            => \$result_dirs,
    'result_dirs_file=s'       => \$result_dirs_file,  # NEW (optional)
    'transcript_matrix_file=s' => \$transcript_matrix_file,
    'gene_matrix_file=s'       => \$gene_matrix_file
);

unless ($expression_metric && ($result_dirs || $result_dirs_file) && $transcript_matrix_file && $gene_matrix_file) {
    print "\n\nRequired parameters missing\n\n";
    print "Usage:\n";
    print "  ./stringtie_expression_matrix.v2.pl --expression_metric=TPM \\\n";
    print "    --result_dirs='sample1,sample2,...' \\\n";
    print "    --transcript_matrix_file=transcript_tpms_all_samples.tsv \\\n";
    print "    --gene_matrix_file=gene_tpms_all_samples.tsv\n\n";
    print "Or (recommended for many samples):\n";
    print "  ./stringtie_expression_matrix.v2.pl --expression_metric=TPM \\\n";
    print "    --result_dirs_file=dirs.list \\\n";
    print "    --transcript_matrix_file=transcript_tpms_all_samples.tsv \\\n";
    print "    --gene_matrix_file=gene_tpms_all_samples.tsv\n\n";
    exit();
}

# Validate metric
chomp($expression_metric);
die "\n\nUnexpected expression metric: $expression_metric (allowed: TPM, FPKM, coverage)\n\n"
    unless ($expression_metric =~ /^tpm$|^fpkm$|^coverage$/i);

# Normalize metric name
my $metric_key = $expression_metric;
$metric_key = 'cov' if ($metric_key =~ /^coverage$/i);

# Read result dirs
my @result_dirs;
if ($result_dirs_file) {
    die "\n\nCould not find result_dirs_file: $result_dirs_file\n\n" unless -e $result_dirs_file;
    my $fh = IO::File->new($result_dirs_file, 'r') or die "Failed to open $result_dirs_file";
    while (my $line = $fh->getline) {
        chomp($line);
        next unless $line =~ /\S/;
        # allow either:
        #   /path/to/sample_dir
        # or sample<TAB>/path/to/sample_dir
        my @cols = split(/\t/, $line);
        my $dir = $cols[-1];
        push @result_dirs, $dir;
    }
    $fh->close;
}
else {
    @result_dirs = split(",", $result_dirs);
}

# Parse and check input dirs
my %samples;
my @sample_list;
my $s = 0;

foreach my $result_dir (@result_dirs) {
    $result_dir =~ s/\s+$//;
    $result_dir =~ s/^\s+//;
    next unless $result_dir;

    die "\n\nCould not find specified result dir: $result_dir\n\n" unless (-e $result_dir && -d $result_dir);
    $s++;

    my $sample_name = $result_dir;
    if ($result_dir =~ /\/([^\/]+)\/?$/) {
        $sample_name = $1;
    }

    push(@sample_list, $sample_name);
    $samples{$s}{name} = $sample_name;
    $samples{$s}{dir}  = $result_dir;
}

my $sample_count = scalar(@sample_list);
my $sample_list_s = join("\t", @sample_list);

print "\n\nProcessing data for the following $sample_count samples:\n";
print join(" ", @sample_list), "\n";

# Parse transcript + gene data per sample
my %trans_data;  # sample_index -> { tid -> exp }
my %gene_data;   # sample_index -> { gid -> exp }

foreach my $s (sort {$a <=> $b} keys %samples) {
    my $dir = $samples{$s}{dir};
    my ($tref, $gref) = get_trans_and_gene_data(
        '-expression_metric' => $metric_key,
        '-dir'               => $dir
    );
    $trans_data{$s} = $tref;
    $gene_data{$s}  = $gref;
}

# Unique transcript IDs
my %tids;
foreach my $s (sort {$a <=> $b} keys %samples) {
    my $data = $trans_data{$s};
    foreach my $tid (keys %{$data}) { $tids{$tid}++; }
}
my $tcount = scalar(keys %tids);
print "\nGathered $expression_metric expression values for $tcount unique transcripts\n";

# Unique gene IDs
my %gids;
foreach my $s (sort {$a <=> $b} keys %samples) {
    my $data = $gene_data{$s};
    foreach my $gid (keys %{$data}) { $gids{$gid}++; }
}
my $gcount = scalar(keys %gids);
print "Gathered $expression_metric expression values for $gcount unique genes\n";

# Write transcript matrix
{
    my $to_fh = IO::File->new($transcript_matrix_file, 'w')
        or die('Failed to open file: ' . $transcript_matrix_file);

    print $to_fh "Transcript_ID\t$sample_list_s\n";
    foreach my $tid (sort keys %tids) {
        my @line = ($tid);
        foreach my $s (sort {$a <=> $b} keys %samples) {
            my $data = $trans_data{$s};
            my $exp = defined($data->{$tid}) ? $data->{$tid}->{exp} : "na";
            push @line, $exp;
        }
        print $to_fh join("\t", @line), "\n";
    }
    $to_fh->close;
    print "\nPrinted transcript $expression_metric expression matrix to $transcript_matrix_file\n";
}

# Write gene matrix
{
    my $go_fh = IO::File->new($gene_matrix_file, 'w')
        or die('Failed to open file: ' . $gene_matrix_file);

    print $go_fh "Gene_ID\t$sample_list_s\n";
    foreach my $gid (sort keys %gids) {
        my @line = ($gid);
        foreach my $s (sort {$a <=> $b} keys %samples) {
            my $data = $gene_data{$s};
            my $exp = defined($data->{$gid}) ? $data->{$gid}->{exp} : "na";
            push @line, $exp;
        }
        print $go_fh join("\t", @line), "\n";
    }
    $go_fh->close;
    print "Printed gene $expression_metric expression matrix to $gene_matrix_file\n\n";
}

exit(0);


sub get_trans_and_gene_data {
    my %args = @_;
    my $metric_key = $args{'-expression_metric'}; # TPM/FPKM/cov
    my $dir        = $args{'-dir'};

    my %trans_exp; # tid -> {exp=>...}
    my %gene_sum;  # gid -> sum(exp)

    # Decide input file: transcripts.gtf -> *.gtf -> t_data.ctab
    my $gtf_file = "$dir/transcripts.gtf";
    my $mode = '';

    if (-e $gtf_file) {
        $mode = 'gtf';
    }
    else {
        my @gtfs = glob("$dir/*.gtf");
        if (@gtfs) {
            $gtf_file = $gtfs[0];
            $mode = 'gtf';
        }
        elsif (-e "$dir/t_data.ctab") {
            $gtf_file = "$dir/t_data.ctab";
            $mode = 'ctab';
        }
        else {
            die "\n\nCould not find input in $dir (expected transcripts.gtf OR *.gtf OR t_data.ctab)\n\n";
        }
    }

    if ($mode eq 'gtf') {
        my $fh = IO::File->new($gtf_file, 'r') or die "Failed to open $gtf_file";
        while (my $line = $fh->getline) {
            chomp($line);
            next if ($line =~ /^\#/);
            my @entry = split("\t", $line);
            next unless @entry >= 9;
            next unless ($entry[2] eq 'transcript');

            my $attrs = $entry[8];

            # accept any transcript_id/gene_id value until next quote
            my ($tid) = $attrs =~ /transcript_id\s+\"([^\"]+)\"\s*;/;
            my ($gid) = $attrs =~ /gene_id\s+\"([^\"]+)\"\s*;/;

            # allow ERCC special case (keep original behavior)
            if (!$tid && $attrs =~ /gene_id\s+\"(ERCC\S+)\"\s*;/) {
                $tid = $1;
                $gid = $1;
            }

            unless ($tid) {
                die "\n\nCould not find transcript id in line: $line\n\n";
            }
            unless ($gid) {
                # if gene_id missing, still allow transcript matrix, but gene matrix would be incomplete
                $gid = "__NO_GENE_ID__";
            }

            my ($exp) = $attrs =~ /\b\Q$metric_key\E\s+\"([^\"]+)\"\s*;/i;
            unless (defined $exp) {
                die "\n\nCould not find expression value ($metric_key) in line: $line\n\n";
            }

            $trans_exp{$tid}{exp} = $exp;
            $gene_sum{$gid} += $exp if ($gid ne "__NO_GENE_ID__");
        }
        $fh->close;
    }
    else { # ctab
        my $fh = IO::File->new($gtf_file, 'r') or die "Failed to open $gtf_file";

        my $header = $fh->getline;
        die "\n\nEmpty file: $gtf_file\n\n" unless defined $header;
        chomp($header);
        my @cols = split(/\t/, $header);

        my %idx;
        for (my $i=0; $i<@cols; $i++) {
            $idx{$cols[$i]} = $i;
        }

        # ballgown t_data.ctab commonly has: t_id, gene_id, cov, FPKM, TPM
        my $tid_col = exists $idx{'t_id'} ? $idx{'t_id'} : (exists $idx{'transcript_id'} ? $idx{'transcript_id'} : undef);
        my $gid_col = exists $idx{'gene_id'} ? $idx{'gene_id'} : undef;

        my $exp_col;
        if ($metric_key =~ /^cov$/i) {
            $exp_col = exists $idx{'cov'} ? $idx{'cov'} : undef;
        } elsif ($metric_key =~ /^FPKM$/i) {
            $exp_col = exists $idx{'FPKM'} ? $idx{'FPKM'} : undef;
        } else { # TPM
            $exp_col = exists $idx{'TPM'} ? $idx{'TPM'} : undef;
        }

        die "\n\nctab missing required columns in $gtf_file\n\n"
            unless defined($tid_col) && defined($gid_col) && defined($exp_col);

        while (my $line = $fh->getline) {
            chomp($line);
            next unless $line =~ /\S/;
            my @e = split(/\t/, $line);
            my $tid = $e[$tid_col];
            my $gid = $e[$gid_col];
            my $exp = $e[$exp_col];

            next unless defined $tid && defined $gid && defined $exp;

            $trans_exp{$tid}{exp} = $exp;
            $gene_sum{$gid} += $exp;
        }
        $fh->close;
    }

    # Convert gene_sum to same structure { gid -> {exp=>...} }
    my %gene_exp;
    foreach my $gid (keys %gene_sum) {
        $gene_exp{$gid}{exp} = $gene_sum{$gid};
    }

    return (\%trans_exp, \%gene_exp);
}

