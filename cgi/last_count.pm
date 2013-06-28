use Net::SNMP;
use DBI;
use Switch;

# константы
my $config_file = "../etc/settings.cfg";   

# Переменные    
my %Config = ();        
my @tabl = ();
my $i = 0;

# Читаем конфигурационный файл                                                                                                                                                     
sub read_config {                                                                                                                                                                  
    my $cfg_fname = shift;                                                                                                                                                         
    my $hash = shift;                                                                                                                                                              
    open(CONFIG, $cfg_fname);                                                                                                                                                      
    while (<CONFIG>) {                                                                                                                                                             
        chomp;      # no newline                                                                                                                                                   
        s/^\s+//;               # no leading white                                                                                                                                 
        s/\s+$//;               # no trailing white                                                                                                                                
        s/\#.*//;               # no comments                                                                                                                                     
        next unless length;     # anything left?                                                                                                                                   
        my ($var, $value) = split(/\s*=\s*/, $_, 2);                                                                                                                               
        $value =~ s/\#.*//;                                                                                                                                                        
        $value =~ s/^\"//;               # no " at start                                                                                                                           
        $value =~ s/\"\s*$//;               # no " at end                                                                                                                          
        $value =~ s/^\s+//;                                                                                                                                                        
        $value =~ s/\s+$//;                                                                                                                                                        
        $$hash{$var} = $value;                                                                                                                                                     
    }                                                                                                                                                                              
    close(CONFIG);                                                                                                                                                                 
}

# Проверяем наличие кофигурационного файла
if (!(-e $config_file)) {                                                                                                                                                          
    warn "[ERROR] Config '$config_file' does not exist!\n";                                                                                                                   
    exit 1;                                                                                                                                                                        
}    

# Читаем глобальный конфиг
read_config($config_file, \%Config);       


# Формат времени
sub ct{
    my $in = shift || 0;
    my $df = shift || 0;
    my ($lsec, $lmin, $lhour, $lday, $lmonth, $lyear) = localtime(time+($df*86400));

    switch ($in) {
	case 1		{ return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $lyear + 1900, $lmonth + 1, $lday, $lhour, $lmin, $lsec); }
	case 2		{ return sprintf("%04d%02d%02d %02d:%02d:%02d", $lyear + 1900, $lmonth + 1, $lday, $lhour, $lmin, $lsec); }
	else		{ return sprintf("%04d%02d%02d", $lyear + 1900, $lmonth + 1, $lday); }
    }
 }

sub show_table {

undef @tabl;

# Подключаемся к БД
my $dbh_Pg = DBI->connect(
        "dbi:Pg:dbname=".$Config{"db_dbname"}.";host=".$Config{"db_server"}.";port=".$Config{"db_port"},
        $Config{"db_user"},
        $Config{"db_password"});

# Проверяем соединение
if (!defined($dbh_Pg)) {
        print "Connect to PostgreSQL Server failed: ".$DBI::errstr;
        die "Connect to PostgreSQL Server failed: ".$DBI::errstr;
}

# формируем запрос и отрисовываем таблицу

my $sel = shift || 2;
my $grp = shift ;

my  $sth = $dbh_Pg->prepare("
select l.l_host, l.l_model, l.l_serial, l.l_dt_event, l.l_black, l.l_color, date_part('day', now() - l.l_dt_event), d.l_destination, l.l_maxt, l.l_curt 
from snmp_log as l
inner join print_dest as d on d.l_host=l.l_host
where uid in (
	SELECT max(uid)
	FROM snmp_log
	group by l_serial
)
and l.l_host like '%$grp%' 
order by 7, $sel
;
");                                                                   

$sth->execute();

while (my @ary = $sth->fetchrow_array())
{
my @tmp=( @ary[0], @ary[1], @ary[2], substr(@ary[3], 0, 19), @ary[4], @ary[5], @ary[6], @ary[7], @ary[8], @ary[9] );     
push(@tabl, [@tmp]);

}

$sth->finish();

return @tabl;

# закрываем соединене
$dbh_Pg->disconnect or print($DBI::errstr."\n");

}
