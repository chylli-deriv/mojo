use Mojo::Base -strict;

use Test::More;
use Mojo::Cookie::Response;
use Mojo::File qw(curfile tempdir);
use Mojo::Transaction::HTTP;
use Mojo::URL;
use Mojo::UserAgent::CookieJar;

subtest 'Missing values' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(Mojo::Cookie::Response->new(domain => 'example.com'));
  $jar->add(Mojo::Cookie::Response->new(name   => 'foo'));
  $jar->add(Mojo::Cookie::Response->new(name   => 'foo',         domain => 'example.com'));
  $jar->add(Mojo::Cookie::Response->new(domain => 'example.com', path   => '/'));
  is_deeply $jar->all, [], 'no cookies';
};

subtest 'Session cookie' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'foo',  value => 'bar'),
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/',    name => 'just', value => 'works')
  );
  my $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',   'right name';
  is $cookies->[0]->value, 'bar',   'right value';
  is $cookies->[1]->name,  'just',  'right name';
  is $cookies->[1]->value, 'works', 'right value';
  is $cookies->[2],        undef,   'no third cookie';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',   'right name';
  is $cookies->[0]->value, 'bar',   'right value';
  is $cookies->[1]->name,  'just',  'right name';
  is $cookies->[1]->value, 'works', 'right value';
  is $cookies->[2],        undef,   'no third cookie';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',   'right name';
  is $cookies->[0]->value, 'bar',   'right value';
  is $cookies->[1]->name,  'just',  'right name';
  is $cookies->[1]->value, 'works', 'right value';
  is $cookies->[2],        undef,   'no third cookie';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',   'right name';
  is $cookies->[0]->value, 'bar',   'right value';
  is $cookies->[1]->name,  'just',  'right name';
  is $cookies->[1]->value, 'works', 'right value';
  is $cookies->[2],        undef,   'no third cookie';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',   'right name';
  is $cookies->[0]->value, 'bar',   'right value';
  is $cookies->[1]->name,  'just',  'right name';
  is $cookies->[1]->value, 'works', 'right value';
  is $cookies->[2],        undef,   'no third cookie';
  $jar->empty;
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0], undef, 'no cookies';
};

subtest '"localhost"' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'localhost',     path => '/foo', name => 'foo', value => 'bar'),
    Mojo::Cookie::Response->new(domain => 'foo.localhost', path => '/foo', name => 'bar', value => 'baz')
  );
  my $cookies = $jar->find(Mojo::URL->new('http://localhost/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
  $cookies = $jar->find(Mojo::URL->new('http://foo.localhost/foo'));
  is $cookies->[0]->name,  'bar', 'right name';
  is $cookies->[0]->value, 'baz', 'right value';
  is $cookies->[1]->name,  'foo', 'right name';
  is $cookies->[1]->value, 'bar', 'right value';
  is $cookies->[2],        undef, 'no third cookie';
  $cookies = $jar->find(Mojo::URL->new('http://foo.bar.localhost/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
  $cookies = $jar->find(Mojo::URL->new('http://bar.foo.localhost/foo'));
  is $cookies->[0]->name,  'bar', 'right name';
  is $cookies->[0]->value, 'baz', 'right value';
  is $cookies->[1]->name,  'foo', 'right name';
  is $cookies->[1]->value, 'bar', 'right value';
  is $cookies->[2],        undef, 'no third cookie';
};

subtest 'Huge cookie' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new->max_cookie_size(1024);
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'small', value => 'x'),
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'big',   value => 'x' x 1024),
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'huge',  value => 'x' x 1025)
  );
  my $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'small',    'right name';
  is $cookies->[0]->value, 'x',        'right value';
  is $cookies->[1]->name,  'big',      'right name';
  is $cookies->[1]->value, 'x' x 1024, 'right value';
  is $cookies->[2],        undef,      'no second cookie';
};

subtest 'Expired cookies' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'example.com',      path => '/foo', name => 'foo', value => 'bar'),
    Mojo::Cookie::Response->new(domain => 'labs.example.com', path => '/', name => 'baz', value => '24', max_age => -1),
    Mojo::Cookie::Response->new(domain => 'labs.example.com', path => '/', name => 'qux', value => 'qux', max_age => 0)
  );
  my $expired = Mojo::Cookie::Response->new(domain => 'labs.example.com', path => '/', name => 'baz', value => '23');
  $jar->add($expired->expires(time - 1));
  my $cookies = $jar->find(Mojo::URL->new('http://labs.example.com/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
};

subtest 'Replace cookie' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'foo', value => 'bar1'),
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'foo', value => 'bar2')
  );
  my $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo',  'right name';
  is $cookies->[0]->value, 'bar2', 'right value';
  is $cookies->[1],        undef,  'no second cookie';
};

subtest 'Switch between secure and normal cookies' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'foo', value => 'foo', secure => 1));
  my $cookies = $jar->find(Mojo::URL->new('https://example.com/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'foo', 'right value';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is scalar @$cookies, 0, 'no insecure cookie';
  $jar->add(Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'foo', value => 'bar'));
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  $cookies = $jar->find(Mojo::URL->new('https://example.com/foo'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
};

subtest '"(" in path' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo(bar', name => 'foo', value => 'bar'));
  my $cookies = $jar->find(Mojo::URL->new('http://example.com/foo(bar'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
  $cookies = $jar->find(Mojo::URL->new('http://example.com/foo(bar/baz'));
  is $cookies->[0]->name,  'foo', 'right name';
  is $cookies->[0]->value, 'bar', 'right value';
  is $cookies->[1],        undef, 'no second cookie';
};

subtest 'Gather and prepare cookies without domain and path' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://mojolicious.org/perldoc/Mojolicious');
  $tx->res->cookies(Mojo::Cookie::Response->new(name => 'foo', value => 'without'));
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://mojolicious.org/perldoc');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo',     'right name';
  is $tx->req->cookie('foo')->value, 'without', 'right value';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://mojolicious.org/perldoc');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo',             'right name';
  is $tx->req->cookie('foo')->value, 'without',         'right value';
  is $jar->all->[0]->name,           'foo',             'right name';
  is $jar->all->[0]->value,          'without',         'right value';
  is $jar->all->[0]->domain,         'mojolicious.org', 'right domain';
  is $jar->all->[1],                 undef,             'no second cookie';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://www.mojolicious.org/perldoc');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'), undef, 'no cookie';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://mojolicious.org/whatever');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'), undef, 'no cookie';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://...many...dots...');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'), undef, 'no cookie';
};

subtest 'Gather and prepare cookies with same name (with and without domain)' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://example.com/test');
  $tx->res->cookies(Mojo::Cookie::Response->new(name => 'foo', value => 'without'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'with', domain => 'example.com'));
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://example.com/test');
  $jar->prepare($tx);
  my $cookies = $tx->req->every_cookie('foo');
  is $cookies->[0]->name,  'foo',  'right name';
  is $cookies->[0]->value, 'with', 'right value';
  is $cookies->[1],        undef,  'no second cookie';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://www.example.com/test');
  $jar->prepare($tx);
  $cookies = $tx->req->every_cookie('foo');
  is $cookies->[0]->name,  'foo',  'right name';
  is $cookies->[0]->value, 'with', 'right value';
  is $cookies->[1],        undef,  'no second cookie';
};

subtest 'Gather and prepare cookies for "localhost" (valid and invalid)' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://localhost:3000');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'local', domain => 'localhost'),
    Mojo::Cookie::Response->new(name => 'bar', value => 'local', domain => 'bar.localhost')
  );
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://localhost:8080');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo',   'right name';
  is $tx->req->cookie('foo')->value, 'local', 'right value';
  is $tx->req->cookie('bar'),        undef,   'no cookie';
};

subtest 'Gather and prepare cookies for unknown public suffix (with IDNA)' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://bücher.com/foo');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(domain => 'com',               path => '/foo', name => 'foo', value => 'bar'),
    Mojo::Cookie::Response->new(domain => 'xn--bcher-kva.com', path => '/foo', name => 'bar', value => 'baz')
  );
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://bücher.com/foo');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo', 'right name';
  is $tx->req->cookie('foo')->value, 'bar', 'right value';
  is $tx->req->cookie('bar')->name,  'bar', 'right name';
  is $tx->req->cookie('bar')->value, 'baz', 'right value';
};

subtest 'Gather and prepare cookies for public suffix (with IDNA)' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://bücher.com/foo');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(domain => 'com',               path => '/foo', name => 'foo', value => 'bar'),
    Mojo::Cookie::Response->new(domain => 'xn--bcher-kva.com', path => '/foo', name => 'bar', value => 'baz')
  );
  $jar->ignore(sub { shift->domain eq 'com' })->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://bücher.com/foo');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'),        undef, 'no cookie';
  is $tx->req->cookie('bar')->name,  'bar', 'right name';
  is $tx->req->cookie('bar')->value, 'baz', 'right value';
};

subtest 'Gather and prepare cookies with domain and path' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://LABS.bücher.Com/perldoc/Mojolicious');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'with', domain => 'labs.xn--bcher-kva.com', path => '/perldoc'),
    Mojo::Cookie::Response->new(name => 'bar', value => 'with', domain => 'xn--bcher-kva.com',      path => '/'),
    Mojo::Cookie::Response->new(
      name   => '0',
      value  => 'with',
      domain => '.xn--bcher-kva.cOm',
      path   => '/%70erldoc/Mojolicious/'
    ),
  );
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://labs.bücher.COM/perldoc/Mojolicious/Lite');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo',  'right name';
  is $tx->req->cookie('foo')->value, 'with', 'right value';
  is $tx->req->cookie('bar')->name,  'bar',  'right name';
  is $tx->req->cookie('bar')->value, 'with', 'right value';
  is $tx->req->cookie('0')->name,    '0',    'right name';
  is $tx->req->cookie('0')->value,   'with', 'right value';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://bücher.COM/perldoc/Mojolicious/Lite');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'),        undef,  'no cookie';
  is $tx->req->cookie('bar')->name,  'bar',  'right name';
  is $tx->req->cookie('bar')->value, 'with', 'right value';
  is $tx->req->cookie('0')->name,    '0',    'right name';
  is $tx->req->cookie('0')->value,   'with', 'right value';
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://labs.bücher.COM/Perldoc');
  $jar->prepare($tx);
  is $tx->req->cookie('foo'),        undef,  'no cookie';
  is $tx->req->cookie('bar')->name,  'bar',  'right name';
  is $tx->req->cookie('bar')->value, 'with', 'right value';
};

subtest 'Gather and prepare cookies with IP address' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://213.133.102.53/perldoc/Mojolicious');
  $tx->res->cookies(Mojo::Cookie::Response->new(name => 'foo', value => 'valid', domain => '213.133.102.53'),
    Mojo::Cookie::Response->new(name => 'bar', value => 'too'));
  $jar->collect($tx);
  $tx = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://213.133.102.53/perldoc/Mojolicious');
  $jar->prepare($tx);
  is $tx->req->cookie('foo')->name,  'foo',   'right name';
  is $tx->req->cookie('foo')->value, 'valid', 'right value';
  is $tx->req->cookie('bar')->name,  'bar',   'right name';
  is $tx->req->cookie('bar')->value, 'too',   'right value';
};

subtest 'Gather cookies with invalid expiration' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://example.com');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'bar', max_age => 'invalid'),
    Mojo::Cookie::Response->new(name => 'bar', value => 'baz', max_age => 86400)
  );
  $jar->collect($tx);
  is $jar->all->[0]->name,  'foo', 'right name';
  is $jar->all->[0]->value, 'bar', 'right value';
  ok !$jar->all->[0]->expires, 'does not expire';
  is $jar->all->[1]->name,  'bar', 'right name';
  is $jar->all->[1]->value, 'baz', 'right value';
  ok $jar->all->[1]->expires, 'expires';
};

subtest 'Gather cookies with invalid domain' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://labs.example.com/perldoc/Mojolicious');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', domain => 'a.s.example.com'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', domain => 'mojolicious.org')
  );
  $jar->collect($tx);
  is_deeply $jar->all, [], 'no cookies';
};

subtest 'Gather cookies with invalid domain (IP address)' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://213.133.102.53/perldoc/Mojolicious');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'valid',   domain => '213.133.102.53.'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'valid',   domain => '.133.102.53'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', domain => '102.53'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', domain => '53')
  );
  $jar->collect($tx);
  is_deeply $jar->all, [], 'no cookies';
};

subtest 'Gather cookies with invalid path' => sub {
  my $jar = Mojo::UserAgent::CookieJar->new;
  my $tx  = Mojo::Transaction::HTTP->new;
  $tx->req->url->parse('http://labs.example.com/perldoc/Mojolicious');
  $tx->res->cookies(
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', path => '/perldoc/index.html'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', path => '/perldocMojolicious'),
    Mojo::Cookie::Response->new(name => 'foo', value => 'invalid', path => '/perldoc.Mojolicious')
  );
  $jar->collect($tx);
  is_deeply $jar->all, [], 'no cookies';
};

subtest 'Load cookies from Netscape cookies.txt file' => sub {
  my $cookies = curfile->dirname->child('cookies');

  subtest 'Not configured' => sub {
    my $jar = Mojo::UserAgent::CookieJar->new;
    is_deeply $jar->load->all, [], 'no cookies';
  };

  subtest 'Missing file' => sub {
    my $jar = Mojo::UserAgent::CookieJar->new;
    is_deeply $jar->file($cookies->child('missing.txt')->to_string)->load->all, [], 'no cookies';
  };

  subtest 'Load file created by curl' => sub {
    my $jar     = Mojo::UserAgent::CookieJar->new;
    my $cookies = $jar->file($cookies->child('curl.txt')->to_string)->load->all;

    is $cookies->[0]->name,      'AEC',        'right name';
    is $cookies->[0]->value,     'Ack',        'right value';
    is $cookies->[0]->domain,    'google.com', 'right domain';
    is $cookies->[0]->path,      '/',          'right path';
    is $cookies->[0]->expires,   4713964099,   'expires';
    is $cookies->[0]->secure,    1,            'is secure';
    is $cookies->[0]->httponly,  1,            'is HttpOnly';
    is $cookies->[0]->host_only, 0,            'allows subdomains';

    is $cookies->[1]->name,      '__Secure-ENID', 'right name';
    is $cookies->[1]->value,     '15.SE',         'right value';
    is $cookies->[1]->domain,    'google.com',    'right domain';
    is $cookies->[1]->path,      '/',             'right path';
    is $cookies->[1]->expires,   4732598797,      'expires';
    is $cookies->[1]->secure,    1,               'is secure';
    is $cookies->[1]->httponly,  1,               'is HttpOnly';
    is $cookies->[1]->host_only, 0,               'allows subdomains';

    is $cookies->[2]->name,      'csv',        'right name';
    is $cookies->[2]->value,     '2',          'right value';
    is $cookies->[2]->domain,    'reddit.com', 'right domain';
    is $cookies->[2]->path,      '/',          'right path';
    is $cookies->[2]->expires,   4761486052,   'expires';
    is $cookies->[2]->secure,    1,            'is secure';
    is $cookies->[2]->httponly,  0,            'not HttpOnly';
    is $cookies->[2]->host_only, 0,            'allows subdomains';

    is $cookies->[3]->name,   'csrf_token',                       'right name';
    is $cookies->[3]->value,  '3329d93c563f6a017045f516c5c515fc', 'right value';
    is $cookies->[3]->domain, 'reddit.com',                       'right domain';
    is $cookies->[3]->path,   '/',                                'right path';
    ok !$cookies->[3]->expires, 'does not expire';
    is $cookies->[3]->secure,    1, 'is secure';
    is $cookies->[3]->httponly,  0, 'not HttpOnly';
    is $cookies->[3]->host_only, 0, 'allows subdomains';

    is $cookies->[4]->name,      'CONSENT',              'right name';
    is $cookies->[4]->value,     'PENDING+648',          'right value';
    is $cookies->[4]->domain,    'whatever.youtube.com', 'right domain';
    is $cookies->[4]->path,      '/about',               'right path';
    is $cookies->[4]->expires,   4761484436,             'expires';
    is $cookies->[4]->secure,    1,                      'is secure';
    is $cookies->[4]->httponly,  0,                      'not HttpOnly';
    is $cookies->[4]->host_only, 0,                      'allows subdomains';

    is $cookies->[5]->name,   'susecom-cookie',   'right name';
    is $cookies->[5]->value,  '50fbf56aa575290e', 'right value';
    is $cookies->[5]->domain, 'www.suse.com',     'right domain';
    is $cookies->[5]->path,   '/',                'right path';
    ok !$cookies->[5]->expires, 'does not expire';
    is $cookies->[5]->secure,    0, 'not secure';
    is $cookies->[5]->httponly,  0, 'not HttpOnly';
    is $cookies->[5]->host_only, 1, 'does not allow subdomains';
  };
};

subtest 'Save cookies to Netscape cookies.txt file' => sub {
  my $tmp = tempdir;

  subtest 'Not configured' => sub {
    my $jar = Mojo::UserAgent::CookieJar->new;
    is_deeply $jar->save->all, [], 'no cookies';
  };

  subtest 'Empty jar' => sub {
    my $file = $tmp->child('empty.txt');
    my $jar  = Mojo::UserAgent::CookieJar->new(file => $file->to_string);

    ok !-e $file, 'file does not exist';
    is_deeply $jar->save->all, [], 'no cookies';
    ok -e $file, 'file exists';
    is_deeply $jar->load->all, [], 'no cookies';

    my $content = $file->slurp;
    like $content, qr/# Netscape HTTP Cookie File/,                                      'Netscape comment is present';
    like $content, qr/# This file was generated by Mojolicious! Edit at your own risk./, 'warning comment is present';
  };

  subtest 'Store standard cookies' => sub {
    my $file = $tmp->child('session.txt');
    my $jar  = Mojo::UserAgent::CookieJar->new(file => $file->to_string);

    $jar->add(Mojo::Cookie::Response->new(domain => 'example.com', path => '/foo', name => 'a', value => 'b'));

    ok !-e $file, 'file does not exist';
    $jar->save;
    ok -e $file, 'file exists';
    my $content = $file->slurp;

    like $content, qr/# Netscape HTTP Cookie File/,                                      'Netscape comment is present';
    like $content, qr/# This file was generated by Mojolicious! Edit at your own risk./, 'warning comment is present';
    like $content, qr/example\.com\tTRUE\t\/foo\tFALSE\t0\ta\tb/,                        'cookie is present';

    my $jar2    = Mojo::UserAgent::CookieJar->new(file => $file->to_string)->load;
    my $cookies = $jar2->all;
    is $cookies->[0]->name,   'a',           'right name';
    is $cookies->[0]->value,  'b',           'right value';
    is $cookies->[0]->domain, 'example.com', 'right domain';
    is $cookies->[0]->path,   '/foo',        'right path';
    ok !$cookies->[0]->expires, 'does not expire';
    ok !$cookies->[1],          'no more cookies';

    $jar2->empty->add(Mojo::Cookie::Response->new(domain => 'mojolicious.org', path => '/', name => 'c', value => 'd'))
      ->save;

    my $jar3 = Mojo::UserAgent::CookieJar->new(file => $file->to_string)->load;
    $cookies = $jar3->all;
    is $cookies->[0]->name,   'c',               'right name';
    is $cookies->[0]->value,  'd',               'right value';
    is $cookies->[0]->domain, 'mojolicious.org', 'right domain';
    is $cookies->[0]->path,   '/',               'right path';
    ok !$cookies->[0]->expires, 'does not expire';
    ok !$cookies->[1],          'no more cookies';
  };
};

subtest 'Stringify cookies in Netscape format' => sub {
  subtest 'Session cookies' => sub {
    my $jar = Mojo::UserAgent::CookieJar->new;
    $jar->add(
      Mojo::Cookie::Response->new(domain => 'mojolicious.org', path => '/',    name => 'c',   value => 'd'),
      Mojo::Cookie::Response->new(domain => 'example.com',     path => '/foo', name => 'foo', value => 'bar')
    );
    my $content = $jar->to_string;
    like $content, qr/mojolicious\.org\tTRUE\t\/\tFALSE\t0\tc\td/,    'first cookie';
    like $content, qr/example\.com\tTRUE\t\/foo\tFALSE\t0\tfoo\tbar/, 'second cookie';
  };

  subtest 'Secure cookies' => sub {
    my $jar = Mojo::UserAgent::CookieJar->new;
    $jar->add(Mojo::Cookie::Response->new(
      domain    => 'www.mojolicious.org',
      path      => '/',
      secure    => 1,
      host_only => 1,
      expires   => 4732598797,
      name      => 'one',
      value     => 'One'
    ));
    my $content = $jar->to_string;
    like $content, qr/www.mojolicious.org\tFALSE\t\/\tTRUE\t4732598797\tone\tOne/, 'first cookie';
  };
};

done_testing();
