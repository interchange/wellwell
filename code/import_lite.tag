UserTag import-lite Order table type
UserTag import-lite AddAttr
UserTag import-lite HasEndTag
UserTag import-lite Interpolate
UserTag import-lite Routine <<EOZ
sub {
    my ($table, $type, $opt, $body) = @_;
    my (@lines, %text, %record, %missing, $name, $db, $msg, $ret, $key);

    # get table handle
    $Tag->perl({tables => $table});

    unless ($db = $Db{$table}) {
        $msg = "[import-lite]: table $table not found.\n";
        Log($msg);
        die($msg);
    }

    # parse body 
    @lines = split(/\n/, $body);

    for my $line (@lines) {
        # skip empty lines at the beginning
        next if $line !~ /\S/ && !$name;

        if ($line =~ /^([\w_]+)\s*:\s*(.*?)\s*$/) {
            $name = $1;

            unless ($db->column_exists($name)) {
                $missing{$name} = 1;
                next;
            }

            $text{$name} = [$2];
        }
        elsif ($name) {
            push @{$text{$name}}, $line;
        }
        else {
            $msg = "[import-lite]: import data for $table starts with text only.\n";
            Log($msg);
            die($msg);
        }
    }

    if (keys %missing) {
        $msg = "[import-lite]: Missing fields in table $table: "
           . join(', ', keys %missing);
        Log($msg);
        die($msg);
    }

    while (my ($name, $value) = each %text) {
        $record{$name} = join("\n", @$value);
    }

    my @columns = $db->columns;

    $key = $columns[0];

Log("Importing to $table: " . uneval(\%record));

    $ret = $db->set_slice(delete $record{$key}, %record);

    return $ret;
}
EOZ
