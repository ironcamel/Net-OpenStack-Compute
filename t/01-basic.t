use Test::Most;

use Net::OpenStack::Compute;

throws_ok(
    sub { Net::OpenStack::Compute->new },
    qr/Missing required arguments/,
    'instantiation with no argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Compute->new( auth_url => 'foo' ) },
    qr/Missing required arguments/,
    'instantiation with only auth_url argument throws an exception'
);

throws_ok(
    sub { Net::OpenStack::Compute->new( auth_url => 'foo', user => 'bar' ) },
    qr/Missing required arguments/,
    'instantiation with only auth_url, user arguments throws an exception'
);



done_testing;
