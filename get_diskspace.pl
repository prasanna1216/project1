#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use lib "/disks/USD_dumps1/bin";
use Filesystems qw($maxfs $max_ageout_fs);

my $usage = "\nUSAGE: ./get_diskspace.pl\n\n\tOptions:\n\t(-sort [sorts on ascending size])\n\t(-total [shows total space allocated to shares])\n\t(-dsort [sorts on descending size])  \n\n";

sub USAGE { print $usage; exit 1; }

my ($sort, $total, $help, $dsort);
my %options=();

my $result = GetOptions( "sort"=>\$sort,
                "total"=>\$total,
                "dsort"=>\$dsort,
                "help!"=>\$help);

        if ($help) {USAGE;}
        if (! $result) {USAGE;}

#my $maxfs = 28;  # Deprecated; now imported from Filesystems.pm
my @sizes=qw(kb Mb G T P);

my @filesystems = (1..$maxfs);
#my @filesystems = (1..46,48,50,51,52,53,54); # Temporary 07/21/16

sub hfree {
        #my $result = `df -Ph @_ | grep / | awk '{print \$4}'`;
        my $result = `sh -c 'df -Ph @_ 2>/dev/null| grep /' | awk '{print \$4}'`;
        chomp $result;
        return $result;}

sub hsize {
        #my $result = `df -Ph @_ | grep / | awk '{print \$2}'`;
        my $result = `sh -c 'df -Ph @_ 2>/dev/null | grep /' | awk '{print \$2}'`;
        chomp $result;
        return $result;}

sub getmax {
        my @sortedlist = sort {$b<=>$a}@_;
        return $sortedlist[0]; }

sub getmin {
        my @sortedlist = sort {$a<=>$b}@_;
        return $sortedlist[0]; }

sub getaverage {
        my @list=@_;
        my $sum;
        foreach (@list) {$sum += $_;}
        return $sum/@list; }

sub gettotal {
        my @list=@_;
        my $sum;
        foreach (@list) {$sum += $_;}
        return $sum; }

sub nfree {
        my ($size) = @_;
        my $i = 0;
        while ($size > 1024) {$size = $size / 1024; $i++;}
        return sprintf("%.0f$sizes[$i]", $size);
}

sub ntotal {
        my ($size) = @_;
        my $i = 0;
        if ($size > 1002) {$size = $size / 1024; $size = $size / 1024;}
        return sprintf("%.0f", $size);
}



print "\n";

my (%free_hash, %free_hash_sort, @free_data, @free_array, @free_tot_array, @size_tot_array, @tot_age_shares, @tot_dump_shares);

print "SHARE\t\t\tFREE\tSHARE SIZE\n";

foreach (@filesystems) {
        my $fs = "/disks/USD_dumps$_";
        my $free_result = `sh -c 'df -Pk $fs 2>/dev/null | grep /' | awk '{print \$4}'`;
        my ($free_result2) = ($free_result =~ m/(\d+)/);
        my $size_result = `sh -c 'df -Pk $fs 2>/dev/null | grep /' | awk '{print \$2}'`;
        my ($size_result2) = ($size_result =~ m/(\d+)/);
        if (!defined $sort) {
                my $free = hfree($fs);
                my $size = hsize($fs);
                print "$fs:\t$free\t ($size)\n";
                }
        # Disabling the line below, so that all FS's are pushed to the "free" calculations.
        # unless ($_ <= $max_ageout_fs ) {
        ## Below, Deprecated by the $max_ageout_fs line above.
        ##unless (($_ eq 1 ) || ($_ eq 2) || ($_ eq 3) || ($_ eq 4) ||
        ##      ($_ eq 5) || ($_ eq 6) || ($_ eq 7) || ($_ eq 8)) {
                        push(@free_array, $free_result2);
        #}
        push(@free_tot_array, $free_result2);
        push(@size_tot_array, $size_result2);
        $free_hash{$fs} = $free_result2;
        $free_hash_sort{$fs} = $free_result2;
        if (($fs eq "/disks/USD_dumps1") || ($fs eq "/disks/USD_dumps2") || ($fs eq "/disks/USD_dumps3") || ($fs eq "/disks/USD_dumps4") || ($fs eq "/disks/USD_dumps5") || ($fs eq "/disks/USD_dumps6") || ($fs eq "/disks/USD_dumps7") || ($fs eq "/disks/USD_dumps8")) {
                push(@tot_age_shares, $free_result2);
        }
        else {
                push(@tot_dump_shares, $free_result2);
        }
}

if (defined $sort) {
        my @sortedlist = sort {$a<=>$b} @free_tot_array;
        foreach (@sortedlist) {
                my $free = $_;
                my @fs = grep { $free_hash_sort{$_} eq $free } keys %free_hash;
                foreach (@fs) {
                        my $free = hfree($_);
                        my $size = hsize($_);
                        print "$_:\t$free\t ($size)\n";
                        $free_hash_sort{$_}="x";
                }
        }
}
elsif (defined $dsort) {
        my @sortedlist = sort {$b<=>$a} @free_tot_array;
        foreach (@sortedlist) {
                my $free = $_;
                my @fs = grep { $free_hash_sort{$_} eq $free } keys %free_hash;
                foreach (@fs) {
                        my $free = hfree($_);
                        my $size = hsize($_);
                        print "$_:\t$free\t ($size)\n";
                        $free_hash_sort{$_}="x";
                }
        }
}


my $min = getmin(@free_array);
my $max = getmax(@free_array);
my $avg = getaverage(@free_array);
my $tot_free_kb = gettotal(@free_tot_array);
my $tot_alloc_kb = gettotal(@size_tot_array);
my $tot_age_kb = gettotal(@tot_age_shares);
my $tot_dump_kb = gettotal(@tot_dump_shares);

$avg = sprintf("%.0f", $avg);
$tot_free_kb = sprintf("%.0f", $tot_free_kb);
$tot_alloc_kb = sprintf("%.0f", $tot_alloc_kb);
$tot_age_kb = sprintf("%.0f", $tot_age_kb);
$tot_dump_kb = sprintf("%.0f", $tot_dump_kb);

my ($minarea) = grep { $free_hash{$_} eq $min } keys %free_hash;
my ($maxarea) = grep { $free_hash{$_} eq $max } keys %free_hash;

my $minfree = hfree($minarea);
my $maxfree = hfree($maxarea);

my $avgfree = nfree($avg);
my $tot_free_gb = ntotal($tot_free_kb);
my $tot_alloc_gb = ntotal($tot_alloc_kb);
my $tot_age_gb = ntotal($tot_age_kb);
my $tot_dump_gb = ntotal($tot_dump_kb);

$tot_free_gb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_free_kb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_alloc_gb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_alloc_kb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_age_gb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_age_kb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_dump_gb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;
$tot_dump_kb =~ s/(\d{1,3}?)(?=(\d{3})+$)/$1,/g;

print "\n";
print " Min:\t$minfree\t  $minarea\n";
print " Max:\t$maxfree\t  $maxarea\n";
print " Avg:\t$avgfree\n";
print "\n Total Free:\t$tot_free_gb"."G\t  $tot_free_kb kb\n";
#print "\n 1-$max_ageout_fs Free:\t$tot_age_gb"."G\t  $tot_age_kb kb\n";
#print " 9-$maxfs Free:\t$tot_dump_gb"."G\t  $tot_dump_kb kb\n";
if ($total) {print "\n Alloc:\t$tot_alloc_gb"."G\t  $tot_alloc_kb kb\n";}
print "\n";

