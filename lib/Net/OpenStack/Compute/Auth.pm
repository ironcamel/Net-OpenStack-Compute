package Net::OpenStack::Compute::Auth;
use Any::Moose;

#use Data::Dumper;
use JSON qw(from_json to_json);
use LWP;

has auth_url     => (is => 'rw', required => 1);
has user         => (is => 'ro', required => 1);
has password     => (is => 'ro', required => 1);
has project_id   => (is => 'ro');
has region       => (is => 'ro');
has service_name => (is => 'ro');
has is_rax_auth  => (is => 'ro', isa => 'Bool'); # Rackspace auth

has _store => (is => 'ro', lazy => 1, builder => '_build_store');

has base_url => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->_store->{base_url} },
);

has token => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->_store->{token} },
);

sub BUILD {
    my ($self) = @_;
    # Make sure trailing slash is removed from auth_url
    my $auth_url = $self->auth_url;
    $auth_url =~ s/\/$//;
    $self->auth_url($auth_url);
}

sub _build_store {
    my ($self) = @_;
    my $auth_url = $self->auth_url;
    my ($version) = $auth_url =~ /(v\d\.\d)$/;
    die "Could not determine version from url [$auth_url]" unless $version;
    return $self->auth_rax() if $self->is_rax_auth;
    return $self->auth_basic() if $version lt 'v2';
    return $self->auth_keystone();
}

sub auth_basic {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($self->auth_url,
        x_auth_user       => $self->user,
        x_auth_key        => $self->password,
        x_auth_project_id => $self->project_id,
    );
    die $res->status_line . "\n" . $res->content unless $res->is_success;

    return {
        base_url   => $res->header('x-server-management-url'),
        token => $res->header('x-auth-token'),
    };
}

sub auth_keystone {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            tenantName => $self->project_id,
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    });
}

sub auth_rax {
    my ($self) = @_;
    return $self->_parse_catalog({
        auth =>  {
            'RAX-KSKEY:apiKeyCredentials' => {
                apiKey   => $self->password,
                username => $self->user,
            }
        }
    });
}

sub _parse_catalog {
    my ($self, $auth_data) = @_;
    my $ua = LWP::UserAgent->new();
    my $res = $ua->post($self->auth_url . "/tokens",
        content_type => 'application/json', content => to_json($auth_data));
    die $res->status_line . "\n" . $res->content unless $res->is_success;
    my $data = from_json($res->content);
    my $token = $data->{access}{token}{id};

    my @catalog = @{ $data->{access}{serviceCatalog} };
    @catalog = grep { $_->{type} eq 'compute' } @catalog;
    die "No compute catalog found" unless @catalog;
    if ($self->service_name) {
        @catalog = grep { $_->{name} eq $self->service_name } @catalog;
        die "No catalog found named " . $self->service_name unless @catalog;
    }
    my $catalog = $catalog[0];
    my $base_url = $catalog->{endpoints}[0]{publicURL};
    if ($self->region) {
        for my $endpoint (@{ $catalog->{endpoints} }) {
            my $region = $endpoint->{region} or next;
            if ($region eq $self->region) {
                $base_url = $endpoint->{publicURL};
                last;
            }
        }
    }

    return { base_url => $base_url, token => $token };
}

=head1 SYNOPSIS

    use Net::OpenStack::Compute::Auth;

    my $auth = Net::OpenStack::Compute::Auth->new(
        auth_url   => $auth_url,
        user       => $user,
        password   => $key,
        project_id => $project_id,
        region     => $region,     # Optional
    );

    my $token = $auth->token;
    my $base_url = $auth->base_url;

=head1 DESCRIPTION

This class is responsible for authenticating for OpenStack.
It supports the old style auth and the new
L<Keystone|https://github.com/openstack/keystone> auth.

=cut

1;
