#!/usr/bin/env perl

#####################################################################################
#
# Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>. See POD section.
#
#####################################################################################

package App::Monupco::dotCloud;
our $VERSION = '0.04';
our $NAME = "monupco-dotcloud-perl";

use App::Monupco::dotCloud::Parser;
@ISA = qw(App::Monupco::dotCloud::Parser);

use strict;
use warnings;

use JSON;
use LWP::UserAgent;

# load dotCloud environment
local $/;
open( my $fh, '<', '/home/dotcloud/environment.json' );
my $json_text   = <$fh>;
my $dotcloud_env = decode_json( $json_text );

my $data = {
    'user_id'    => $dotcloud_env->{'MONUPCO_USER_ID'},
    'app_name'   => $dotcloud_env->{'DOTCLOUD_PROJECT'}.".".$dotcloud_env->{'DOTCLOUD_SERVICE_NAME'},
    'app_uuid'   => $dotcloud_env->{'DOTCLOUD_WWW_HTTP_HOST'},
    'app_type'   => "perl",
    'app_url'    => $dotcloud_env->{'DOTCLOUD_WWW_HTTP_URL'},
    'app_vendor' => 1,   # dotCloud
    'pkg_type'   => 400, # Perl / CPAN
    'installed'  => [],
};

my $pod_parsed = "";
my $parser = App::Monupco::dotCloud::Parser->new();
$parser->output_string( \$pod_parsed );
$parser->parse_file("/home/dotcloud/perl5/lib/perl5/x86_64-linux-thread-multi/perllocal.pod");

my @installed;
foreach my $nv (split(/\n/, $pod_parsed)) {
    my @name_ver = split(/ /, $nv);
    push(@installed, {'n' => $name_ver[0], 'v' => $name_ver[1]});
}


$data->{'installed'} = [ @installed ];

my $json_data = to_json($data); # , { pretty => 1 });

my $ua = new LWP::UserAgent(('agent' => "$NAME/$VERSION"));

# will URL Encode by default
my $response = $ua->post('https://monupco-otb.rhcloud.com/application/register/', { json_data => $json_data});

if (! $response->is_success) {
    die $response->status_line;
}

my $content = from_json($response->decoded_content);
print "Monupco: $content->{'message'}\n";

exit $content->{'exit_code'};


1;
__END__

=head1 NAME

App::Monupco::dotCloud - monupco.com registration agent for dotCloud / Perl applications

=head1 SYNOPSIS

To register your dotCloud Perl application to Monupco do the following:

1) Create a Perl application on dotCloud

2) Add a dependency in your Makefile.PL file

    PREREQ_PM => {
        'App::Monupco::dotCloud' => 0,
        ...
    },

3) Set your userID. You can get it from https://monupco-otb.rhcloud.com/profiles/mine/

    dotcloud var set <app name> MONUPCO_USER_ID=UserID

4) Enable the registration script in your postinstall hook. **Note:**
If you are using an "approot" your `postinstall` script should be in the 
directory pointed by the "approot" directive of your `dotcloud.yml`.
For more information about `postinstall` turn to 
http://docs.dotcloud.com/guides/postinstall/.

If a file named `postinstall` doesn't already exist, create it and add the following:

        #!/bin/sh
        /home/dotcloud/perl5/lib/perl5/App/Monupco/dotCloud.pm

5) Make `postinstall` executable

        chmod a+x postinstall

6) Then push your application to dotCloud

    dotcloud push <app name>

7) If everything goes well you should see something like:

        19:55:10 [www.0] Running postinstall script...
        19:55:13 [www.0] response:200
        19:55:13 [www.0] Monupco: Success, registered/updated application with id 34

That's it, you can now check your application statistics at
<http://monupco.com>


=head1 DESCRIPTION

This module compiles a list of locally installed Perl distributions and sends it to
http://monupco.com where you check your application statistic and available updates.

=head1 AUTHOR

Alexander Todorov, E<lt>atodorov()otb.bgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>

 This module is free software and is published under the same terms as Perl itself.

=cut
