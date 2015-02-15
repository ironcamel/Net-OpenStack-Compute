# NAME

Net::OpenStack::Compute - Bindings for the OpenStack Compute API.

# VERSION

version 1.1200

# SYNOPSIS

    use Net::OpenStack::Compute;
    my $compute = Net::OpenStack::Compute->new(
        auth_url     => 'https://identity.api.rackspacecloud.com/v2.0',
        user         => 'alejandro',
        password     => 'password',
        region       => 'ORD',
    );
    $compute->create_server({
        name      => 'server1',
        flavorRef => $flav_id,
        imageRef  => $img_id,
    });

# DESCRIPTION

This class is an interface to the OpenStack Compute API.
Also see the [oscompute](https://metacpan.org/pod/oscompute) command line tool.

# METHODS

Methods that take a hashref data param generally expect the corresponding
data format as defined by the OpenStack API JSON request objects.
See the
[OpenStack Docs](http://docs.openstack.org/api/openstack-compute/1.1/content)
for more information.
Methods that return a single resource will return false if the resource is not
found.
Methods that return an arrayref of resources will return an empty arrayref if
the list is empty.
Methods that create, modify, or delete resources will throw an exception on
failure.

## new

Creates a client.

params:

- auth\_url

    Required. The url of the authentication endpoint. For example:
    `'https://identity.api.rackspacecloud.com/v2.0'`

- user

    Required.

- password

    Required.

- region

    Optional.

- project\_id

    Optional.

- service\_name

    Optional.

- verify\_ssl

    Optional. Defaults to 1.

- is\_rax\_auth

    Optional. Defaults to 0.

## get\_server

    get_server($id)

Returns the server with the given id or false if it doesn't exist.

## get\_servers

    get_servers(%params)

params:

- detail

    Optional. Defaults to 0.

- query

    Optional query string to be appended to requests.

Returns an arrayref of all the servers.

## get\_servers\_by\_name

    get_servers_by_name($name)

Returns an arrayref of servers with the given name.
Returns an empty arrayref if there are no such servers.

## create\_server

    create_server({ name => $name, flavorRef => $flavor, imageRef => $img_id })

Returns a server hashref.

## delete\_server

    delete_server($id)

Returns true on success.

## rebuild\_server

    rebuild_server($server_id, { imageRef => $img_id })

Returns a server hashref.

## set\_password

    set_password($server_id, $new_password)

Returns true on success.

## get\_vnc\_console

    get_vnc_console($server_id[, $type=novnc])

Returns a url to the server's VNC console

## get\_networks

    get_networks($id)

Returns a network list
.
&#x3d;head2 get\_image

    get_image($id)

Returns an image hashref.

## get\_images

    get_images(%params)

params:

- detail

    Optional. Defaults to 0.

- query

    Optional query string to be appended to requests.

Returns an arrayref of all the images.

## create\_image

    create_image($server_id, { name => 'bob' })

Returns an image hashref.

## delete\_image

    delete_image($id)

Returns true on success.

## get\_flavor

    get_flavor($id)

Returns a flavor hashref.

## get\_flavors

    get_flavors(%params)

params:

- detail

    Optional. Defaults to 0.

- query

    Optional query string to be appended to requests.

Returns an arrayref of all the flavors.

## token

    token()

Returns the OpenStack Compute API auth token.

## base\_url

    base_url()

Returns the base url for the OpenStack Compute API, which is returned by the
server after authenticating.

# SEE ALSO

- [oscompute](https://metacpan.org/pod/oscompute)
- [OpenStack Docs](http://docs.openstack.org/api/openstack-compute/1.1/content)

# AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
