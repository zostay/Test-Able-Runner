package Test::Able::Runner::Role::Meta::Class;
use Moose::Role;

use Module::Pluggable sub_name => 'test_modules';

has base_package => (
    is        => 'rw',
    isa       => 'ArrayRef[Str] | Str',
    predicate => 'has_base_package',
);

has test_packages => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_test_packages',
);

has test_path => (
    is        => 'rw',
    isa       => 'ArrayRef[Str] | Str ',
    required  => 1,
    default   => sub { 't/lib' },
);

sub test_classes {
    my $meta = shift;

    # Use Module::Pluggable to find the test classes
    if ($meta->has_base_package) {
        my $base_package = $meta->base_package;
        $meta->search_path( 
            new => (ref $base_package ? @$base_package : $base_package) 
        );
        return $meta->test_modules;
    }

    # Use the exact list given
    elsif ($meta->has_test_packages) {
        return @{ $meta->test_packages };
    }

    # Probably shouldn't happen...
    return ();
}

sub build_test_objects {
    my $meta = shift;

    # Insert our test paths into the front of the @INC search path
    my $test_path = $meta->test_path;
    unshift @INC, (ref $test_path ? @$test_path : $test_path);

    my @test_objects;
    PACKAGE: for my $test_class ($meta->test_classes) {
        unless (Class::MOP::load_class($test_class)) {
            warn $@ if $@;
            warn "FAILED TO LOAD $test_class. Skipping.";
            next PACKAGE;
        }

        {
            no strict 'refs';
            next PACKAGE if ${$test_class."::NOT_A_TEST"};
        }

        push @test_objects, $test_class->new;
    }

    return \@test_objects;
}

sub setup_test_objects {
    my $meta = shift;
    $meta->test_objects($meta->build_test_objects);
};

__PACKAGE__->meta->add_method(search_path  => \&search_path);
__PACKAGE__->meta->add_method(test_modules => \&test_modules);

1;
