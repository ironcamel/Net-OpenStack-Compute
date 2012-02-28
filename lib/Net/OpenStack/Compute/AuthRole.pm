package Net::OpenStack::Compute::AuthRole;
use Any::Moose 'Role';

has auth_url     => (is => 'rw', required => 1);
has user         => (is => 'ro', required => 1);
has password     => (is => 'ro', required => 1);
has project_id   => (is => 'ro');
has region       => (is => 'ro');
has service_name => (is => 'ro');
has is_rax_auth  => (is => 'ro', isa => 'Bool'); # Rackspace auth

1;
