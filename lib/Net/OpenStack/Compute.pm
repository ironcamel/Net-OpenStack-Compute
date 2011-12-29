package Net::OpenStack::Compute;
use Any::Moose;

# VERSION

use Carp;
use HTTP::Request;
use JSON qw(from_json to_json);
use LWP;
use Net::OpenStack::Compute::Auth;

has auth_url   => (is => 'ro', isa => 'Str', required => 1);
has user       => (is => 'ro', isa => 'Str', required => 1);
has password   => (is => 'ro', isa => 'Str', required => 1);
has project_id => (is => 'ro', isa => 'Str', required => 1);
has region     => (is => 'ro');

has _auth => (
    is   => 'rw',
    isa  => 'Net::OpenStack::Compute::Auth',
    lazy => 1,
    default => sub {
        my $self = shift;
        Net::OpenStack::Compute::Auth->new(
            auth_url   => $self->auth_url,
            user       => $self->user,
            password   => $self->password,
            project_id => $self->project_id,
            region     => $self->region,
        );
    },
);

has _base_url => (
    is   => 'ro',
    isa  => 'Str',
    lazy => 1,
    default => sub { shift->_auth->base_url },
);

has _ua => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new();
        $agent->default_header(x_auth_token => $self->_auth->token);
        return $agent;
    },
);

sub get_servers {
    my ($self, %params) = @_;
    my $res = $self->_ua->get($self->_url('/servers', $params{detail}));
    return from_json($res->content)->{servers};
}

sub get_server {
    my ($self, $id) = @_;
    my $res = $self->_ua->get($self->_url("/servers/$id"));
    return from_json($res->content)->{server};
}

sub create_server {
    my ($self, %params) = @_;
    my ($name, $flavor, $image) = @params{qw(name flavor image)};
    croak "name param is required"   unless defined $name;
    croak "flavor param is required" unless defined $flavor;
    croak "image param is required"  unless defined $image;

    my $res = $self->_ua->post(
        $self->_url('/servers'),
        content_type => 'application/json',
        Content => to_json({
            server => {
                name      => $name,
                imageRef  => $image,
                flavorRef => $flavor,
            }
        })
    );
    _check_res($res);
    return from_json($res->content)->{server};
}

sub delete_server {
    my ($self, $id) = @_;
    my $req = HTTP::Request->new(DELETE => $self->_url("/servers/$id"));
    my $res = $self->_ua->request($req);
    _check_res($res);
    return 1;
}

sub get_images {
    my ($self, %params) = @_;
    my $res = $self->_ua->get($self->_url('/images', $params{detail}));
    return from_json($res->content)->{images};
}

sub get_image {
    my ($self, $id) = @_;
    my $res = $self->_ua->get($self->_url("/images/$id"));
    return from_json($res->content)->{image};
}

sub create_image {
    my ($self, %params) = @_;
    my ($name, $server, $meta) = @params{qw(name server meta)};
    croak "name param is required"   unless defined $name;
    croak "server param is required" unless defined $server;
    croak "meta param must be a hashref" if $meta and ! ref($meta) == 'HASH';
    $meta ||= {};

    my $res = $self->_ua->post($self->_url("/servers/$server/action"),
        content_type => 'application/json',
        Content => to_json({
            createImage => {
                name     => $name,
                metadata => $meta,
            }
        }),
    );
    _check_res($res);
    return from_json($res->content);
}

sub delete_image {
    my ($self, $id) = @_;
    my $req = HTTP::Request->new(DELETE => $self->_url("/images/$id"));
    my $res = $self->_ua->request($req);
    _check_res($res);
    return 1;
}

sub get_flavors {
    my ($self, %params) = @_;
    my $res = $self->_ua->get($self->_url('/flavors', $params{detail}));
    return from_json($res->content)->{flavors};
}

sub get_flavor {
    my ($self, $id) = @_;
    my $res = $self->_ua->get($self->_url("/flavors/$id"));
    return from_json($res->content)->{flavor};
}

sub _url {
    my ($self, $path, $is_detail) = @_;
    my $url = $self->_base_url . $path;
    $url .= '/detail' if $is_detail;
    return $url;
}

sub _check_res { croak $_[0]->content unless $_[0]->is_success }

# ABSTRACT: Bindings for the OpenStack compute api.

=head1 SYNOPSIS

    use Net::OpenStack::Compute;
    my $compute = Net::OpenStack::Compute->new(
        auth_url   => $auth_url,
        user       => $user,
        password   => $password,
        project_id => $project_id,
        region     => $region, # Optional
    );
    $compute->create_server(name => 's1', flavor => $flav_id, image => $img_id);

=head1 DESCRIPTION

This is the main class responsible for interacting with OpenStack Compute.
Also see L<oscompute> for the command line tool that is a wrapper for this
class.

=head1 METHODS

=head2 get_server

    get_server($id)

=head2 get_servers

    get_servers()
    get_servers(detail => 0) # Detail defaults to 1.

=head2 create_server

    create_server(name => $name, flavor => $flavor, image => $image)

=head2 delete_server

    delete_server($id)

=head2 get_image

    get_image($id)

=head2 get_images

    get_images()
    get_images(detail => 0) # Detail defaults to 1.

=head2 create_image

    create_image(name => $name, server => $server_id)

=head2 delete_image

    delete_image($id)

=head2 get_flavor

    get_flavor($id)

=head2 get_flavors

    get_flavors()
    get_flavors(detail => 0) # Detail defaults to 1.

=cut

1;
