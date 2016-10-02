package Log::Any::Adapter::FileWriteRotate;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use parent qw(Log::Any::Adapter::Base);

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

sub init {
    require File::Write::Rotate;

    my ($self) = @_;
    $self->{default_level} //= 'warning';
    $self->{min_level}     //= $self->{default_level};

    $self->{_fwr} = File::Write::Rotate->new(
        dir         => $self->{dir},
        prefix      => $self->{prefix},
        (suffix      => $self->{suffix})      x !!defined($self->{suffix}),
        (size        => $self->{size})        x !!defined($self->{size}),
        (histories   => $self->{histories})   x !!defined($self->{histories}),
        (buffer_size => $self->{buffer_size}) x !!defined($self->{buffer_size}),
    );
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;

            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

            $self->{_fwr}->write($msg);
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my $self = shift;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
# ABSTRACT: Send logs to File::Write::Rotate

=for Pod::Coverage ^(init)$

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('FileWriteRotate',
     dir          => '/var/log',    # required
     prefix       => 'myapp',       # required
     #suffix      => '.log',        # default is ''
     size         => 25*1024*1024,  # default is 10MB, unless period is set
     histories    => 12,            # default is 10
     #buffer_size => 100,           # default is none
 );


=head1 DESCRIPTION

This Log::Any adapter prints log messages to file through
L<File::Write::Rotate>.


=head1 SEE ALSO

L<Log::Any>

L<File::Write::Rotate>
