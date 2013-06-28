#!/usr/bin/perl

# Для пущего порядку
use strict;
use warnings;
use CGI qw(:cgi);
use Template;
use last_count;

my $uri_base = 'http://print/';

# Этот модуль реализует протокол FastCGI.
use FCGI;

# Открываем сокет
# наш скрипт будет слушать порт 9000
# длина очереди соединений (backlog)- 5 штук
my $socket = FCGI::OpenSocket(":9009", 5);

# Начинаем слушать
my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $socket);

# Бесконечный цикл
# при каждом принятом запросе выполняется один "оборот" цикла.
while($request->Accept() >= 0) {
# Внутри цикла происходит выполнение всей полезной работы


my $parser = Template->new (INCLUDE_PATH => '../tpl/');
# print header ();
$parser->process('index.tpl', 
    {
	matrix	=> \&show_table,
	ct	=> &ct(1),
	uri_base => $uri_base
    }
)  
or die $parser->error;
};
