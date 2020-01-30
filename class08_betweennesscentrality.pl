#!/usr/bin/perl -w

local $edges = [];

while(defined(my $edge = <STDIN>)) {
    chomp($edge);
    my ($v1, $v2) = split(/\t/, $edge);
    push(@$edges, [$v1, $v2]);
}

local %vertex_to_adj_list;
local $v1_list;
local $v2_list;
local $max_v = 0;

sub unique {
    my $input_array = $_[0];
    my @input_arra = @$input_array;
    my %seen = ();
    foreach my $elem (@input_arra) {
        $seen{$elem} = 1;
    }
    return(sort(keys(%seen)));
}

foreach my $edge (@$edges) {
    $v1 = $edge->[0];
    if ($v1 > $max_v) {
        $max_v = $v1;
    }
    $v2 = $edge->[1];
    if ($v2 > $max_v) {
        $max_v = $v2;
    }
    $v1_list = $vertex_to_adj_list{$v1};
    $v2_list = $vertex_to_adj_list{$v2};
    if (! defined($v1_list)) {
        $v1_list = [];
        $vertex_to_adj_list{$v1} = $v1_list;
    }
    if (! defined($v2_list)) {
        $v2_list = [];
        $vertex_to_adj_list{$v2} = $v2_list;
    }
    push(@$v1_list, int($v2));
    push(@$v2_list, int($v1));
}

my @vertex_names = sort keys(%vertex_to_adj_list);
my @adjacency_lists;
foreach my $v (@vertex_names) {
    my @neighbors = unique($vertex_to_adj_list{$v});
    my $v_int = int($v);
    $adjacency_lists[$v_int] = \@neighbors;
}
local $V = scalar(@adjacency_lists);

local $queue_head = [];
local $queue_tail = $queue_head;

sub queue_inject($) {
    my $elem = $_[0];
    $queue_tail->[0] = $elem;
    $queue_tail->[1] = [];
    $queue_tail = $queue_tail->[1];
}

sub queue_eject() {
    if ($queue_head == $queue_tail) {
        return(undef);
    }
    my $elem = $queue_head->[0];
    $queue_head = $queue_head->[1];
    return($elem);
}

sub breadth_first_search_with_paths_and_weights($) {
    my $s = $_[0];
    my $dists = [(-1) x $V];
    my $paths = [];
    my $weights = [];
    for (my $i = 0; $i < $V; ++$i) {
        $paths->[$i] = [];
    }
    $dists->[$s] = 0;
    $weights->[$s] = 1;
    queue_inject($s);
    my $orders = [];
    while(defined($u = queue_eject())) {
        my $u_neighbors = $adjacency_lists[$u];
        foreach my $v (@$u_neighbors) {
            if ($dists->[$v] < 0) {
                $dists->[$v] = $dists->[$u] + 1;
                $weights->[$v] = $weights->[$u];
                queue_inject($v);
                unshift(@$orders, $v);
                push(@{ $paths->[$v] }, $u);
            }
            else {
                if ($dists->[$v] == $dists->[$u] + 1) {
                    push(@{ $paths->[$v] }, $u);
                    $weights->[$v] = $weights->[$u] + $weights->[$v];
                }
            }
        }
    }
    return([$dists, $paths, $weights, $orders]);
}

my @start_time = times;

sub min (@)  {
    my @array = @_;
    my $cur_min = $array[0];
    foreach my $i (1..$#array) {
        if ($array[$i] < $cur_min) {
            $cur_min = $array[$i];
        }
    }
    return($cur_min);
}

sub betweenness_centrality() {
    my $final_scores = [(0) x $V];
    for (my $s = 0; $s < $V; ++$s) {
        my $ret_vals = breadth_first_search_with_paths_and_weights($s);
        my $dists = $ret_vals->[0];
        my $paths = $ret_vals->[1];
        my $weights = $ret_vals->[2];
        my $orders = $ret_vals->[3];
        my @s_scores = (1) x $V;
        foreach my $v (@$orders) {
            my $neighbors = $paths->[$v];
            foreach my $neighbor (@$neighbors) {
                $s_scores[$neighbor] = $s_scores[$neighbor] +
                    $s_scores[$v]*($weights->[$neighbor])/($weights->[$v]);
            }
        }
        foreach my $u (0..($V - 1)) {
            $final_scores->[$u] = $final_scores->[$u] + $s_scores[$u];
        }
    }
    return($final_scores);
}

my $bc = betweenness_centrality();

foreach my $v (0..($V - 1)) {
    print "betweenness centrality for node $v is: " . $bc->[$v] . "\n";
}
# my $ret_vals = breadth_first_search(0);

# my $dists = $ret_vals->[0];
# my $paths = $ret_vals->[1];
# my $weights = $ret_vals->[2];

# print "distances are: \n";
# for (my $i = 0; $i < $V; ++$i) {
#     print "distance to node $i: " . $dists->[$i] . "\n";
#     print "weight of node $i: " . $weights->[$i] . "\n";
#     my @shortest_path_dag = @{ $paths->[$i] };
#     print "shortest-path DAG for node $i is: @shortest_path_dag\n";
# }

