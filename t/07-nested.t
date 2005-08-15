
use strict;
use warnings;

use Test::More 'no_plan';

{
    package WebApp::Foo::Bar::Baz;
    use Test::More;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context;
    sub conf_driver {
        my $self = shift;
        return $self->param('conf_driver');
    }

    sub setup {
        my $self = shift;

        $self->header_type('none');
        $self->run_modes(
            'start' => 'default',
        );

        $ENV{'SCRIPT_NAME'} = '/tony';
        $ENV{'PATH_INFO'}   = '/baz';
        $ENV{'SITE_NAME'}   = 'fred';

        my $conf_driver = $self->conf_driver;
        $self->conf('one')->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'SCRIPT_NAME'} = '/tony';
        $ENV{'PATH_INFO'}   = '/simon';
        $ENV{'SITE_NAME'}   = 'fred';

        $self->conf('two')->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );


        $ENV{'SCRIPT_NAME'} = '/tony';
        $ENV{'PATH_INFO'}   = '/simon';
        $ENV{'SITE_NAME'}   = 'wubba';

        $self->conf('three')->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'SCRIPT_NAME'} = '/baker';
        $ENV{'PATH_INFO'}   = '/fred';
        $ENV{'SITE_NAME'}   = 'gordon';

        $self->conf('four')->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

        $ENV{'SCRIPT_NAME'} = '/tony';
        $ENV{'PATH_INFO'}   = '';
        $ENV{'SITE_NAME'}   = 'gordon';

        $self->conf('five')->init(
            file   => "t/conf-$conf_driver/07-nested.conf",
            driver => $conf_driver,
            driver_options => {
                ConfigScoped => {
                    warnings => {
                        permissions => 'off',
                    }
                }
            }
        );

    }

    sub default {
        my $self = shift;

        my $config;

        # site=fred; loc=/tony/baz
        $config = $self->conf('one')->context;
        is($config->{'foo'},             1,        $self->conf_driver . ': 1.foo');
        ok(!$config->{'gordon'},                   $self->conf_driver . ': 1.gordon');
        is($config->{'slash_tony'},      1,        $self->conf_driver . ': 1./tony');
        is($config->{'fred'},            1,        $self->conf_driver . ': 1.fred');
        ok(!$config->{'simon'},                    $self->conf_driver . ': 1.simon');
        is($config->{'winner'},          'foo',    $self->conf_driver . ': 1.winner');  # not longest, but most deeply nested
        is($config->{'location_winner'}, '/tony',  $self->conf_driver . ': 1.location_winner');
        is($config->{'site_winner'},     'fred',   $self->conf_driver . ': 1.site_winner');
        is($config->{'app_winner'},      'foo',    $self->conf_driver . ': 1.app_winner');

        # site=wubba; loc=/tony/simon
        $config = $self->conf('three')->context;
        ok(!$config->{'foo'},                      $self->conf_driver . ': 2.foo');
        ok(!$config->{'gordon'},                   $self->conf_driver . ': 2.gordon');
        is($config->{'slash_tony'},      1,        $self->conf_driver . ': 2./tony');
        ok(!$config->{'fred'},                     $self->conf_driver . ': 2.fred');
        ok(!$config->{'simon'},                    $self->conf_driver . ': 2.simon');
        is($config->{'winner'},          '/tony',  $self->conf_driver . ': 2.winner');
        is($config->{'location_winner'}, '/tony',  $self->conf_driver . ': 2.location_winner');
        ok(!$config->{'site_winner'},              $self->conf_driver . ': 2.site_winner');
        ok(!$config->{'app_winner'},               $self->conf_driver . ': 2.app_winner');

        # site=gordon; loc=/baker/fred
        $config = $self->conf('four')->context;
        ok(!$config->{'foo'},                      $self->conf_driver . ': 3.foo');
        ok(!$config->{'gordon'},                   $self->conf_driver . ': 3.gordon');
        ok(!$config->{'slash_tony'},               $self->conf_driver . ': 3./tony');
        ok(!$config->{'fred'},                     $self->conf_driver . ': 3.fred');
        ok(!$config->{'simon'},                    $self->conf_driver . ': 3.simon');
        ok(!$config->{'winner'},                   $self->conf_driver . ': 3.winner');
        ok(!$config->{'location_winner'},          $self->conf_driver . ': 3.location_winner');
        ok(!$config->{'site_winner'},              $self->conf_driver . ': 3.site_winner');
        ok(!$config->{'app_winner'},               $self->conf_driver . ': 3.app_winner');

        # site=gordon; loc=/tony
        $config = $self->conf('five')->context;
        ok(!$config->{'foo'},                      $self->conf_driver . ': 4.foo');
        is($config->{'gordon'},          1,        $self->conf_driver . ': 4.gordon');
        is($config->{'slash_tony'},      1,        $self->conf_driver . ': 4./tony');
        ok(!$config->{'fred'},                     $self->conf_driver . ': 4.fred');
        ok(!$config->{'simon'},                    $self->conf_driver . ': 4.simon');
        is($config->{'winner'},          'gordon', $self->conf_driver . ': 4.winner');  # not longest or highest priority, but most deeply nested
        is($config->{'location_winner'}, '/tony',  $self->conf_driver . ': 4.location_winner');
        is($config->{'site_winner'},     'gordon', $self->conf_driver . ': 4.site_winner');
        ok(!$config->{'app_winner'},               $self->conf_driver . ': 4.app_winner');

        return "";
    }
}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigGeneral' })->run;
    }
    else {
        skip "Config::General not installed", 36;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'ConfigScoped'  })->run;
    }
    else {
        skip "Config::Scoped not installed", 36;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        WebApp::Foo::Bar::Baz->new(PARAMS => { conf_driver => 'XMLSimple'     })->run;
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", 36;
    }
}



sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}

