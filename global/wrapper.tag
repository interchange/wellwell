UserTag wrapper Order class
UserTag wrapper AddAttr
UserTag wrapper Routine <<EOR
sub {
    my ($class, $opt) = @_;
    my (%args, $object, $scratch_var);

    # copy tag attributes, drop class and reparse
    %args = %$opt if $opt;
    delete $args{class};
    delete $args{reparse};
    $scratch_var = delete $args{scratch};

    # load class
    eval "require $class";

    if ($@) {
        die "[wrapper]: Failed to load class $class: $@";
    }

    eval {
        $object = $class->new(%args);
    };

    if ($@) {
        die "[wrapper] Failed to instantiate class $class: $@";
    }

    if ($scratch_var) {
        $Scratch->{$scratch_var} = $object;
    }

    return $object;
}
EOR
