package Net::OpenStack::Compute;
use Moose;

# VERSION

use Carp;
use HTTP::Request;
use JSON qw(to_json);
use LWP;

has token    => (is => 'ro');
has base_url => (is => 'ro');
has agent => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $agent = LWP::UserAgent->new();
        $agent->default_header(x_auth_token => $self->token);
        return $agent;
    },
);

sub get_servers {
    my ($self) = @_;
    my $base_url = $self->base_url;
    return $self->agent->get("$base_url/servers/detail")->content;
}

sub get_server {
    my ($self, $id) = @_;
    my $base_url = $self->base_url;
    return $self->agent->get("$base_url/servers/$id")->content;
}

sub create_server {
    my ($self, %params) = @_;
    my ($name, $flavor, $image) = @params{qw(name flavor image)};
    croak "name param is required"   unless defined $name;
    croak "flavor param is required" unless defined $flavor;
    croak "image param is required"  unless defined $image;
    my $base_url = $self->base_url;

    my $res = $self->agent->post(
        "$base_url/servers",
        content_type => 'application/json',
        Content => to_json({
            server => {
                name      => $name,
                imageRef  => $image,
                flavorRef => $flavor,
            }
        })
    );
    return $res->content;
}

sub delete_server {
    my ($self, $id) = @_;
    my $base_url = $self->base_url;

    my $req = HTTP::Request->new('DELETE', "$base_url/servers/$id");
    my $res = $self->agent->request($req);
    return $res->is_success;
}

# ABSTRACT: Bindings for the OpenStack compute api.

=head1 SYNOPSIS

    use Net::OpenStack::Compute;
    my $compute = Net::OpenStack::Compute->new(
        base_url => 'http://...',
        token    => 'secret',
    );
    $compute->get_servers();

=head1 METHODS

=head2 get_server($id)

=head2 get_servers()

=head2 create_server(name => $name, flavor => $flavor, image => $image)

=head2 delete_server($id)

=cut

'Net::OpenStack::Compute';
