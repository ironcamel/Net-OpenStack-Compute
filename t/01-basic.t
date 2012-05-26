use Test::Most;

use Net::OpenStack::Compute;

throws_ok(
    sub { Net::OpenStack::Compute->new },
    qr/Missing required arguments/,
    'instantiation with no argument throws an exception'
);


done_testing;
