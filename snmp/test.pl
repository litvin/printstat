#!/usr/bin/perl

use Net::SNMP;
use DBI;

# константы
my $config_file = "/opt/printstat2/settings.cfg";   

# Переменные    
my %Config = ();        
@OID = ();

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

# Подключаем справочник OID
require $Config{"oid_file"};

# Формат времени
sub ct{ 
    my $in = $_[0];
    my ($lsec, $lmin, $lhour, $lday, $lmonth, $lyear) = localtime();
    if (defined($in)) {
        ($lsec, $lmin, $lhour, $lday, $lmonth, $lyear) = localtime($in);
    }
    my $res = sprintf("%04d%02d%02d", $lyear + 1900, $lmonth + 1, $lday);
    return($res);
}


# собираем хосты принтеров из конфига CUPS
open (MYFILE, "<", $Config{"cups_config"});
while (<MYFILE>) {
my	  $line = $_;
    $pname = $1 if $line =~ /^\<Printer (.+)\>/i;
    $model = $1 if $line =~ /^Info (.+)/i;
    $dnsname = $1 if $line =~ /^DeviceURI socket\:\/\/(.+)\:/i;
    $destination = $1 if $line =~ /^Location (.+)/i;
    if ( $line =~ /\<\/Printer\>/i ) { 
#print $pname." ";
#print $model." ";
#print $dnsname." ";
#print $destination."\n";
		@hosts[$i] = $dnsname; 
		$i++;
	}
}
close (MYFILE);


# Получаем данные с принтера по SNMP, в качестве параметров передаем host и OID, возваращаем error в случае неудачи
sub var_snmp {

my ($session, $error) = Net::SNMP->session(
      -hostname  => shift || 'localhost',
      -community => $Config{"community"} || 'public',
);
   
my $OID = shift;
	#проверяем доступность
	if (!defined $session) {
	MyLog ( "ERROR: ".$error."\n");
	return "error";
	} else {
	#получаем данные
	my $result = $session->get_request(-varbindlist => [ $OID ],);
		#проверяем данные
		if (!defined $result) {
			$session->close();
			return "error";
		} else {
			$session->close();
			return $result->{ $OID };
		}
	}
}



# получаем данные по SNMP
	my $hostname = "ssh-print27";
	my $model = "";
		foreach (@OID) {
		$model = var_snmp($hostname, $_);
		print "1 ".$hostname." ".$model ;

		if ($model ne "error") 
		{
		my $s =  var_snmp($hostname, $OidSerial{$model});
		my $b =  var_snmp($hostname, $OidBlack{$model});
		if ( defined $OidColor{$model}) { $c = var_snmp($hostname, $OidColor{$model}); }else{ $c = 0; }
		print  $hostname." ".$model." ".$s." ".$b." ".$c."\n";
			
		# формируем запрос и добавляем данные в таблицу
		print $hostname."  ".$model."  ".$s."  ".$b."  ".$c."\n";
		
		last; 
		}
	}


print ct()." End \n";


