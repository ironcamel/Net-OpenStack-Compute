package Net::OpenStack::Compute::Auth;
use Any::Moose;

use JSON qw(from_json to_json);
use LWP;

has auth_url   => (is => 'rw', isa => 'Str', required => 1);
has user       => (is => 'ro', isa => 'Str', required => 1);
has password   => (is => 'ro', isa => 'Str', required => 1);
has project_id => (is => 'ro');
has region     => (is => 'ro');
has _store     => (is => 'ro', lazy => 1, builder => '_build_store');

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
    return $version eq 'v1.1' ? $self->auth_basic() : $self->auth_keystone();
}

sub auth_basic {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($self->auth_url,
        x_auth_user       => $self->user,
        x_auth_key        => $self->password,
        x_auth_project_id => $self->project_id,
    );
    #say $res->headers->as_string;
    die $res->status_line . "\n" . $res->content unless $res->is_success;

    return {
        base_url   => $res->header('x-server-management-url'),
        token => $res->header('x-auth-token'),
    };
}

sub auth_keystone {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    my $auth_data = {
        auth =>  {
            passwordCredentials => {
                username => $self->user,
                password => $self->password,
            }
        }
    };

    my $res = $ua->post($self->auth_url . "/tokens",
        content_type => 'application/json', Content => to_json($auth_data));
    
    die $res->status_line . "\n" . $res->content unless $res->is_success;
    my $data = from_json($res->content);
    my $token = $data->{access}{token}{id};

    my ($catalog) =
        grep { $_->{type} eq 'compute' } @{$data->{access}{serviceCatalog}};
    die "No compute service catalog found" unless $catalog;

    my $base_url = $catalog->{endpoints}[0]{publicURL};
    if ($self->region) {
        for my $endpoint (@{ $catalog->{endpoints} }) {
            if ($endpoint->{region} eq $self->region) {
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
        project_id => $project_id, # Optional
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
