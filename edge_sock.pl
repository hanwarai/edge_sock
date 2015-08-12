#EDGE Libraries includes BSD Socket Library
#use with perl 5.003 or later
#
#Version 1.243 (build 990217)
$version = "1.243";
#
#(c) 1996-1999 Livin' on the EDGE Limited.,
#and taka@edge.co.jp,tsuka@edge.co.jp
#
#�����������Ѿ���������������������������������������������������������
#Socket.pm��Fcntl.pm��ɬ�פǤ���perl��library�Υǥ��쥯�ȥ������å����Ƥ���������
#nslookup�Υѥ�������å����Ƥ�������������/usr/sbin����/usr/bin�ˤ���ޤ���
#lock library�Υƥ��Ȥ�ԤäƤ�������
#������������������������������������������������������������������������
#
#
$db_suffix = ".db"; #Berckley DB(BSD��OS)�ξ��
#$db_suffix = ".dir"; #NDBM(Solaris��)�ξ��

use Socket;
require 5.003;
use File::Copy 'cp';

sub touch
# file����
# ����ˡ: &touch( file );
# ��: &touch ("/export/home/www/tmp");
# �֤��� : �ʤ�
{
	my $file = shift;
	if ($file  =~ /[;><&\*'\|]/) {
	        &htmldie(__LINE__, "Program Alert: What are you trying to do!? $!\n");
	}
	open (DUMMY,">$file") || &htmldie(__LINE__,"cannot open file : $!\n");
	close (DUMMY);

}

sub mkpasswd2
# make randam string for password
# Usage: &mkpasswd2( passwordlength, seedstring );
# Example: &mkpasswd2( 8, "foo" );
# Return Value: newly created password string
{
  my $length = shift;
  my $seed = shift;
  $seed = $seed ? $seed : &mkpasswd(2);
  my $passwd;
  my $str = "a b c d e f g h i j k m n p q r s t u w x y z A B C D E F G H J K L M N P Q R S T U W X Z 1 2 3 4 5 6 7 8 9";
  my @chars;
  my $i;

  srand( $seed );
  @chars = split( / /, $str );
  for ( ; $i<$length ; $i++ )
  {
    $passwd .= $chars[ int(rand( @chars ))];
  }
  $passwd;
}

sub mkpasswd
# make randam string for password
# Usage: &mkpasswd( passwordlength );
# Example: &mkpasswd( 8 );
# Return Value: newly created password string
{
  ( my $length ) = @_;
  my $passwd;
  my $str = "a b c d e f g h i j k m n p q r s t u w x y z A B C D E F G H J K L M N P Q R S T U W X Z 1 2 3 4 5 6 7 8 9";
  my @chars;
  my $i;

  srand( time | $$ );
  @chars = split( / /, $str );
  for ( ; $i<$length ; $i++ )
  {
    $passwd .= $chars[ int(rand( @chars ))];
  }
  $passwd;
}


sub readtbl
# �ơ��֥���ɤ߹���
# ����ˡ : &readtbl( �ե�����̾ );
# ������ : �ơ��֥������
{
  local( $file ) = @_;
  local( @tbl );

  open( FILE, "$file" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( FILE );
  while(<FILE>)
  {
    s/\n$//;
    push (@tbl, $_ );
  }
  &unlock( FILE );
  close FILE;
  @tbl;
}

sub DBMrsort{
# DBM�ե������value�򾮤�����˥����Ȥ���key���֤�
# ����ˡ : &DBMsort(�ե�����̾);
#          &DBMsort(�ե�����̾, ��);
# ������ : &DBMsort($file, 10);
# �֤��� : �����Υꥹ��

  local($file) = shift;
  local($num) = shift;

  &DBMsort($file, $num, 'r');
}

sub DBMsort{
# DBM�ե������value���礭����˥����Ȥ���key���֤�
# ����ˡ : &DBMsort(�ե�����̾);
#          &DBMsort(�ե�����̾, ��);
#          &DBMsort(�ե�����̾, ��, 'r'); DBMrsort��
# ������ : &DBMsort($file, 10);
# �֤��� : �����Υꥹ��

  local($file) = shift;
  local($num) = shift;
  local($rev) = shift;
  local($sep) = $defaultsep ? $defaultsep : "\t";
  local(@keys);

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  unless($rev eq 'r'){
    @keys = sort {$FILE{$b} <=> $FILE{$a}} keys %FILE;
  }
  else{
    @keys = sort {$FILE{$a} <=> $FILE{$b}} keys %FILE;
  }

  @keys = @keys[$[..$[+$num-1] if $num;

  dbmclose( %FILE );
  &unlock( DUMMY );
  close DUMMY;

  @keys;
}


sub DBMkeys{
# DBM�ե�������Υ������֤�
# ����ˡ : &DBMkeys(�ե�����̾);
# ������ : &DBMexist($file);
# �֤��� : �����Υꥹ��

  local($file) = shift;
  local($sep) = $defaultsep ? $defaultsep : "\t";
  local(@keys);

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  @keys = keys %FILE;

  dbmclose( %FILE );
  &unlock( DUMMY );
  close DUMMY;

  @keys;
}


sub DBMexist
# DBM�ե�������˥�����¸�ߤ��뤫�ɤ���Ĵ�٤�.
# ����ˡ : &DBMexist( �ե�����̾, ���� );
# ������ : &DBMexist( $file, $key );
# �֤��� : �� : ¸�ߤ���, �� : ¸�ߤ��ʤ�
{
  my $file = shift;
  my $key = shift;
  my $sep = $defaultsep ? $defaultsep : "\t";
  my $exist;

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  $exist = defined $FILE{"$key"};

  &unlock( DUMMY );
  close DUMMY;
  dbmclose( %FILE );

  $exist;
}

sub DBMstore
# DBM�ե�������Υ����˥ǡ����ꥹ�Ȥ������
# ����ˡ : &DBMstore( �ե�����̾, ����, �ǡ����ꥹ�� );
# ������ : &DBMstore( $file, $key, @data );
{
  my $file = shift;
  my $key = shift;
  my @data = @_;
  my $sep = $defaultsep ? $defaultsep : "\t";

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  $FILE{"$key"} = join( $sep, @data );

  &unlock( DUMMY );
  close DUMMY;
  dbmclose( %FILE );
}

sub DBMfetch
# DBM�ե�������Υ����Υǡ����ꥹ�Ȥ��ɤ߽Ф�
# ����ˡ : &DBMfetch( �ե�����̾, ���� );
# ������ : &DBMfetch( $file, $key );
# �֤��� : �ǡ����ꥹ��
{
  my $file = shift;
  my $key = shift;
  my @data;
  my $sep = $defaultsep ? $defaultsep : "\t";

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  @data = split( $sep, $FILE{"$key"} );

  &unlock( DUMMY );
  close DUMMY;
  dbmclose( %FILE );

  @data;
}


sub DBMdelete
# DBM�ե�������Υ�����������.
# ����ˡ : &DBMdelete( �ե�����̾, ���� );
# ������ : &DBMfetch( $file, $key );
{
  my $file = shift;
  my $key = shift;
  my $sep = $defaultsep ? $defaultsep : "\t";

  unless ( -e "$file$db_suffix" ) {
    dbmopen( %FILE, "$file", 0660 ) ;
    dbmclose( %FILE );
  }
  open( DUMMY, ">>$file$db_suffix" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( DUMMY );
  dbmopen( %FILE, "$file", 0660 )
  || &htmldie(__LINE__, "Can't open dbmfile: $!\n");

  delete $FILE{"$key"};

  &unlock( DUMMY );
  close DUMMY;
  dbmclose( %FILE );
}


sub count
# ��������ѥե�������Υ�����ȿ������ο�����[��/��]������
# ���λ��꤬�ʤ����ϥޥ��å����󥯥����(ex. ABCD0001 -> ABCD0002)
# ����0����ꤹ��Ȳ��⤻�����ߤΥե���������(=������ȿ�)���֤�
# ����ˡ: &count( �ե�����[, ��] );
# ������: $id = &count( $maxidfile, -1 ); # �ǥ������(1��������)
#         $id = &count( $maxidfile );   # �ޥ��å����󥯥����
#         $presentid = &count( $maxidfile, 0 ); # ���ߤΥ�����ȿ���Ĵ�٤�
# �֤���: [��/��]����Υ�����ȿ�, �ޤ��ϸ��ߤΥ�����ȿ�(0�����)
# ��  ��: �ե��������ο����η����� /^[0-9]*\n?$/ �ޤ��� /^[A-Za-z]*[0-9]*$/
#         �ޤ���ä���Ū�Υե�����ʳ������̤Υե�����ˤ��δؿ�����Ѥ���
#         ���ޤä����, �ե��������Ȥ�ü������Ƥ��ޤ������礭���Τ����.
{
  my $file = shift;
  my $count = shift;
  my $number;


  if( -e $file )
  {
    cp ($file, $file.".old"); # �Хå����å�
  }
  else
  {
    touch ($file); # �ե����뤬�ʤ���к��
  }

  open( COUNT, "+<$file" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( COUNT );
  $number = <COUNT>;

  unless( defined $count && $count == 0 )
  {
    if( defined $count )
    {
      $number += $count; # ���ꤵ�줿���������󥯥����/�ǥ������
    }
    else
    {
      $number =~ s/\n//; # �ޥ��å����󥯥���ȤΤ�������\n����
      $number++; # ʸ�����ޥ��å����󥯥����
    }
    truncate( COUNT, 0 ); # �ե����륵������0�ˤ���(�ǥ�����Ȼ����к�)
#    open( ZERO, ">$file" ) && close( ZERO ); # truncate ����������Ƥʤ����
    seek( COUNT, 0, 0 ); # �ե�����ݥ��󥿤���Ƭ�˰�ư
    print COUNT $number;
  }
  &unlock( COUNT );
  close( COUNT );

  $number;
}


sub open_socket_connection
#Socket�򥪡��ץ󤹤롣
#����ˡ:&open_socket_connection(FILEHANDLE, ��³����hostname, port�ֹ�);
#�֤���:���ơ�������1:����; 0:���ԡ�
{
	my $file_handle = shift;
	my $remotehost = shift;
	my $port = shift;

	my  $proto = getprotobyname( 'tcp' );

	my $thataddr = gethostbyname( $remotehost );
	unless ($thataddr) {
		 return (0);
	}
	my $sin = sockaddr_in($port,inet_aton($remotehost));


	# �����åȤ򥪡��ץ�
	 socket( $file_handle, PF_INET, SOCK_STREAM, $proto ) || return (0);


	# �����åȤ��⡼�ȥͥåȥ�����ɥ쥹�˥��ͥ���
	connect( $file_handle, $sin ) || return (0);
	my $oldhandle = select($file_handle); $| = 1; select($oldhandle);	# �����åȤ�Хåե���󥰤��ʤ�

	1;
}

sub close_socket_connection
#Socket�򥯥������롣
#����ˡ:&open_socket_connection(FILEHANDLE);
#�֤���:���ơ�������1:������
{
	my $file_handle = shift;
	close($file_handle);
	1;
}

sub get_html_status
#����URL��html�ե����뤽��¾��¸�ߤ��뤫�ɤ����Τ���롣
#����ˡ:&get_html_status(URL, timeout��)
#�֤���:HTTP���ơ��������إå�����unable_to_connect
{
		my $url = shift;
		my $timeout = shift;
		$SIG{'ALRM'} = "html_status_timeout";
		alarm ($timeout);

		my $user_agent = "Cyberhorse/0.2";
		chop( my $user_host = `hostname` );
		my $user_protcol = "HTTP/1.0";

		my $port;

		# �ݡ����ֹ�����
		if ($url =~/^http:\/\//i) {
			$port = 80;
			$url =~s/http:\/\///i;
		} else {
			return "unable_to_connect";
		}

		# �ۥ���̾���ǥ��쥯�ȥ�����
		my $remotehost,$string;
		($remotehost,$string) = split(/\//,$url,2);
		unless ($string) {
			$string = "\/";
		} else {
			$string = "\/".$string;
		}
		&open_socket_connection(HTTP, $remotehost, $port) || return "unable_to_connect";

		my @status;
		print HTTP "HEAD $string $user_protcol\n";
		print HTTP "User-Agent: $user_agent\n";
		print HTTP "Host: $user_host\n\n";
		while (<HTTP>){
			push(@status,$_);
		 }

		$SIG{'ALRM'} = "DEFAULT";
		&close_socket_connection (HTTP);
		@status;

}

sub html_status_timeout {
		&close_socket_connection (HTTP);
		$SIG{'ALRM'} = "DEFAULT";
		"timeout";
}


sub jlocaltimestr
# return localtime() value in particular string format
# Usage: &localtimestr( time );
# Example: $date = &localtimestr( time );
# Notice: 'time' in usage must be time() value format.
{
  ( my $now ) = @_;

  local( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $now );
  $year += 1900 ;                             # 98/03/12 tsuka@edge.co.jp
  $mon++;

  "$yearǯ$mon��$mday�� $hour��$minʬ$sec��"; # 98/03/12 tsuka@edge.co.jp
}


sub localtimestr
# return localtime() value in particular string format
# Usage: &localtimestr( time );
# Example: $date = &localtimestr( time );
# Notice: 'time' in usage must be time() value format.
{
  ( my $now ) = @_;

  local( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $now );
  $year += 1900 ;                        # 98/03/12 tsuka@edge.co.jp
#  $year = sprintf "%02d", ($year%100) ;  # ����4����Ϥ����Ϥ��ιԤ򥳥��ȥ����Ȥ���
  $mon  = sprintf "%02d", $mon+1 ;
  $mday = sprintf "%02d", $mday ;
  $hour = sprintf "%02d", $hour ;
  $min  = sprintf "%02d", $min ;
  $sec  = sprintf "%02d", $sec ;

  "$year/$mon/$mday $hour:$min:$sec";
}

sub logadd
# simply add log to the end of a file
# Usage: logadd( filename, LIST );
# Example: logadd( report.log, @data );
{
  my $file = shift;
  my @data = @_;
  my $sep = $defaultsep ? $defaultsep:'	';

  open( LOG, ">>$file" ) || &htmldie(__LINE__, "Can't open logfile: $!\n");
  &lock( LOG );
  seek( LOG, 0, 2 );
  print LOG join( $sep, @data );
  print LOG "\n";
  &unlock( LOG );
  close LOG;
}

sub htmldie
# 'die' for html
# Usage:   &htmldie(__LINE__, LIST);
# Example: &htmldie(__LINE__, "Can't find data file: $!\n");
{
  (my $line, my $mes) = @_;
  print $mes;
  print " at ".__FILE__." line ".$line."\n" if ( $mes !~ /\n/ );
  print "</body>\n</html>\n";
  die "\n";
}

sub lock
#lock file(s)
#Usage: &lock( FILEHANDLE );
{
my $LOCK_EX = 2;
foreach $file ( @_ )
{
   select(( select( $file ), $| = 1 )[0]); # no buffering mode
      flock($file, $LOCK_EX);
	}
}

sub unlock
#unlock file(s)
#Usage: &unlock( FILEHANDLE );
{
	my $LOCK_UN = 8;
	foreach $file ( @_ )
	  {
	     flock($file, $LOCK_UN);
		 select(( select( $file ), $| = 0 )[0]); # buffering mode
	}
}

sub mail_id
# �᡼�������(��å�����ID��Date�إå��դ�)
# ����ˡ : &mail_id(
#������smtp�����Х��ɥ쥹, from���ɥ쥹,��å�����,��å�����ID,to���ɥ쥹�Υꥹ��);
# �֤��� :
{
	my $local_smtp = shift;
	my $admin = shift;
	my $mes = shift;
	my $mes_id_num = shift;
	my @address_cluster = @_;
	my $error = 1;
	my $header;
	my ($checked,
		$hello,
		$from,
		$data,
		$rcpt,
		$sent,
		$rcpt_in_progress,
		$rcpt_success,
		$address);

    my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdat) =
        gmtime(time + 60 * 60 * 9);
	my ($date_header, $port, $mes_id, $mes_id_seq);
	#my $hostname = hostname();
	chop( my $hostname = `hostname` );

	$year += 1900 ;
	$mes_id_seq ++;
	$mes_id
	= sprintf("Message-Id: <%04d%02d%02d%02d%02d%02d%s\.%s\.joinus\@%s>",
	$year, $mon, $mday, $hour, $min, $sec, $mes_id_num, $mes_id_seq, $hostname);
    $wday = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")[$wday];
    $mon = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct"
, "Nov", "Dec")[$mon];
    $date_header = sprintf("Date: %s, %02d %s %04d %02d:%02d:%02d +0900",
			$wday,$mday,$mon,$year,$hour,$min,$sec);
	$mes =~s/\r\n/\n/g;
	$mes =~s/\n/\r\n/g;


	unless ($local_smtp) {return (0);}
		unless (@address_cluster) {return (0);}

	foreach(@address_cluster) {
		unless (&echeck($_)) {
				return (0);
		}
	}

	unless ($mes =~/Date:/) {
		$header = "$date_header\r\n";
	}
	unless ($mes =~/Message-Id:/) {
		$header .= "$mes_id\r\n";
	}
	unless ($mes =~/X-Mailer:/) {
		$header .= "X-Mailer: joinus $version\r\n";
	}
	unless ($mes =~/MIME-Version:/) {
		$header .= "MIME-Version: 1.0\r\n";
	}
	unless ($mes =~/Content-Transfer-Encoding:/) {
		$header .= "Content-Transfer-Encoding: 7bit\r\n";
	}
	unless ($mes =~/Content-Type:/) {
		$header .= "Content-Type: text/plain; charset=\"ISO-2022-JP\"\r\n";
	}
	$mes = $header.$mes;

	open (DATA,">/var/tmp/mes.txt");
	print DATA $mes;
	close (DATA);

	$port = getservbyname( 'smtp', 'tcp' );	# SMTP�ݡ����ֹ����

	$SIG{'ALRM'} = "smtp_status_timeout";
	alarm (120);
	&open_socket_connection(SMTP, $local_smtp, $port) || return (0);

	while( <SMTP> )	{
		if(( /^220/ ) && !$hello ) {
						$hello++;
			print SMTP "HELO $local_smtp\r\n";
			# HELO���ޥ��(full address)
		} elsif ( /^250/ && !$from && $hello ) {
						$from ++;
						print SMTP "MAIL From: <$admin>\r\n";
			# MAIL From:���ޥ��(<from address>)

		} elsif( /^250/ && !$rcpt && $from && !$rcpt_in_progress) {
			$address = shift (@address_cluster);
						# RCPT To: ���ޥ��(<to address>)
			 		print SMTP "RCPT To: <$address>\r\n";
			$rcpt_in_progress ++;

		} elsif( /^[2345]/ && !$rcpt && $rcpt_in_progress ) {
					if (/^25[01]/) {
					$rcpt_success++;
				}
							if ($address = shift (@address_cluster)) {
						# RCPT To: ���ޥ��(<to address>)
					print SMTP "RCPT To: <$address>\r\n";
						 	} else {
										$rcpt++;
						undef $rcpt_in_progress;
					unless ($rcpt_success) {
						$checked++;
					}
								$data ++;
								print SMTP "DATA\r\n";		# DATA���ޥ��
				}

		} elsif( /^354/ && !$sent && $data ) {
				 		$sent ++;
				print SMTP $mes;
				print SMTP "\r\n.\r\n";			#�᡼��������λ

		} elsif( /^250/ && $sent ) {
			$checked++;

			#���顼����
		} elsif( /^[45]/ && !$rcpt_in_progress ) {
				$checked++;
		}
		last if $checked;
	}
	print SMTP "QUIT\r\n";

	&close_socket_connection (SMTP);
	$SIG{'ALRM'} = "DEFAULT";
	$error;
}


sub mail
# �᡼�������
# ����ˡ : &mail( ������smtp�����Х��ɥ쥹, from���ɥ쥹,��å�����,to���ɥ쥹�Υꥹ��);
# �֤��� :
{
	my $local_smtp = shift;
	my $admin = shift;
	my $mes = shift;
	my @address_cluster = @_;
	my $header;
	$mes =~s/\r\n/\n/g;
	$mes =~s/\n/\r\n/g;

	unless ($local_smtp) {return (0);}
    unless (@address_cluster) {return (0);}

	foreach(@address_cluster) {
		unless (&echeck($_)) {
				return (0);
		}
	}

	$header = "X-Mailer: Join Us $version\r\n";
	$header .= "MIME-Version: 1.0\r\n";
	$header .= "Content-Transfer-Encoding: 7bit\r\n";
	$header .= "Content-Type: text/plain; charset=\"ISO-2022-JP\"\r\n";
	$mes = $header.$mes;

	my $port = getservbyname( 'smtp', 'tcp' );	# SMTP�ݡ����ֹ����

	$SIG{'ALRM'} = "smtp_status_timeout";
	alarm (120);
	&open_socket_connection(SMTP, $local_smtp, $port) || return (0);

	my $checked;
	my $hello;
	my $from;
	my $data;
	my $rcpt;
	my $sent;
	my $rcpt_in_progress;
	my $rcpt_success;
	my $address;
	my $error = 1;


	while( <SMTP> )	{
		if(( /^220/ ) && !$hello ) {
            $hello++;
			print SMTP "HELO $local_smtp\r\n";
			# HELO���ޥ��(full address)
		} elsif ( /^250/ && !$from && $hello ) {
            $from ++;
            print SMTP "MAIL From: <$admin>\r\n";
			# MAIL From:���ޥ��(<from address>)

		} elsif( /^250/ && !$rcpt && $from && !$rcpt_in_progress) {
			$address = shift (@address_cluster);
            # RCPT To: ���ޥ��(<to address>)
       		print SMTP "RCPT To: <$address>\r\n";
			$rcpt_in_progress ++;

		} elsif( /^[2345]/ && !$rcpt && $rcpt_in_progress ) {
		    	if (/^25[01]/) {
					$rcpt_success++;
				}
            	if ($address = shift (@address_cluster)) {
            # RCPT To: ���ޥ��(<to address>)
					print SMTP "RCPT To: <$address>\r\n";
             	} else {
                    $rcpt++;
	    			undef $rcpt_in_progress;
					unless ($rcpt_success) {
						$checked++;
					}
            		$data ++;
            		print SMTP "DATA\r\n";		# DATA���ޥ��
				}

		} elsif( /^354/ && !$sent && $data ) {
	       		$sent ++;
				print SMTP $mes;
				print SMTP "\r\n.\r\n";			#�᡼��������λ

		} elsif( /^250/ && $sent ) {
			$checked++;

			#���顼����
		} elsif( /^[45]/ && !$rcpt_in_progress ) {
				$checked++;
		}
		last if $checked;
	}
	print SMTP "QUIT\r\n";

	&close_socket_connection (SMTP);
	$SIG{'ALRM'} = "DEFAULT";
	$error;
}


sub addresscheck {
# e-mail ���ɥ쥹������å�����
# ����ˡ : &addresscheck( e-mail���ɥ쥹�Υꥹ�� );
# �֤��� : ����ʥ��ɥ쥹�Υꥹ��

	my @addresses = @_;
	my @newaddresses;
	chop( my $localhost = `hostname` );
	my $admin = "postmaster\@$localhost";

	foreach $address ( @addresses ) {
	    local( $login, $domain ) = split( /@/, $address );


	    my $remotehost = &gethost( $domain ) if $domain;	# �ɥᥤ��̾����

	    if( $remotehost ) {
			my $port = getservbyname( 'smtp', 'tcp' );	# SMTP�ݡ����ֹ����

			$SIG{'ALRM'} = "smtp_status_timeout";
			alarm (120);
			&open_socket_connection(SMTP, $remotehost, $port) || return (0);

	        my $checked;
	        my $hello;
	        my $from;
	        my $rcpt;

	        while( <SMTP> )	{
print $_;
				if(( /^220/ ) && !$hello ) {
		            $hello++;
		            print SMTP "HELO $localhost\r\n";	# HELO���ޥ��(full address)
				} elsif ( /^250/ && !$from && $hello ) {
		            $from ++;
		            print SMTP "MAIL From: <$admin>\r\n";	# MAIL From:���ޥ��(<from address>)
				} elsif( /^250/ && !$rcpt && $from ) {
		            $rcpt ++;
		            print SMTP "RCPT To: <$address>\r\n";	# RCPT To: ���ޥ��(<to address>)
				} elsif( (/^25[01]/) && $rcpt ) {

					# 250:����
					# 251:�ե������ɽ��(mailer��ž�����ʤ�)
					# 450:�᡼��ܥå������ӥ���

		            @newaddresses = ( @newaddresses, $address );
		            $checked++;

				} elsif( /^[0-9]{3}/ && $rcpt ) {
					$checked++;
				}
				last if $checked;
			}
			print SMTP "QUIT\r\n";

			&close_socket_connection (SMTP);
			$SIG{'ALRM'} = "DEFAULT";
		}
	}
	@newaddresses;
}

sub smtp_status_timeout {
	&close_socket_connection (SMTP);
	$SIG{'ALRM'} = "DEFAULT";
	0;
}


sub gethost
# �ɥᥤ��̾�����������ɤ����򸡺�����
# ����ˡ : &gethost( �ɥᥤ��̾ );
# �֤��� : �����Ѥߥɥᥤ��̾(�ޤ��ϥۥ���̾)
#          ̤��� : �ɥᥤ��¸�ߤ��ʤ�
{
  my $domain = shift;
  my $host;

	# type =MX
  $host = &nslookuphost( $domain, MX, 'mail exchanger = ' );
	# type = A
  $host = $host ? $host : &nslookuphost( $domain, A, 'Name:    ' );
}

sub nslookuphost
# nslookup���Ѥ��ƥɥᥤ��̾�򸡺�����. ������( MX or A )�ȥѥ��������.
# ����ˡ : &nslookuphost( �ɥᥤ��̾, ������, �ѥ����� );
# �֤��� : �����Ѥߥɥᥤ��̾(�ޤ��ϥۥ���̾)
#          ̤��� : �ɥᥤ��¸�ߤ��ʤ�
{
  my $domain = shift;
  my $type = shift;
  my $pattern = shift;
  my $host;

	if ($domain  =~ /[;><&\*'\|]/) {
	        die "Program Alert: What are you trying to do!? $!\n";
	}

  open ( SAVEERR, ">&STDERR" );	# ɸ�२�顼���Ϥ�Хå����å�
  close( STDERR );		# ɸ�२�顼���Ϥ򥯥���

  open( NS, "/usr/sbin/nslookup -type=$type $domain |" ) || &htmldie(__LINE__, "Can't find nslookup: $!\n");
  while(<NS>)
  {
    if( s/.*$pattern(.*)/$1/ )
    {
      ( $host = $_ ) =~ s/\n//;
      last;
    };
  }
  close( NS );

  open( STDERR, ">&SAVEERR" );	# �Хå����åפ���ɸ�२�顼���Ϥ�����

  $host;
}

sub echeck {
# email���ɥ쥹�����������ɤ����򸡺�����
# ����ˡ : &echeck( email���ɥ쥹 );
# �֤��� : �������ʤ�᡼�륢�ɥ쥹���֤�
#          ̤��� : email���ɥ쥹���������ʤ�

	my ( $mail_address ) = shift;

	my ( @parts ) = split( /\@/, $mail_address ) ;	# local-port @ domain
	return if ( @parts != 2 ) ;
	return if ( !$parts[0] ) ;
	return if ( !$parts[1] ) ;

	return if ( grep( /[\x80-\xFF]/, @parts ) ) ;	# ASCII�ʳ�
	return if ( grep( /[\x00-\x1F]/, @parts ) ) ;	# ����ʸ�� \x00-\x1F
	return if ( grep( /\x20/, @parts ) ) ;		# ���ڡ��� \x20
	return if ( grep( /\x22/, @parts ) ) ;		# �ü� "   \x22
	return if ( grep( /\x28/, @parts ) ) ;		# �ü� (   \x28
	return if ( grep( /\x29/, @parts ) ) ;		# �ü� )   \x29
	return if ( grep( /\x2C/, @parts ) ) ;		# �ü� ,   \x2C
	return if ( grep( /\x3A/, @parts ) ) ;		# �ü� :   \x3A
	return if ( grep( /\x3B/, @parts ) ) ;		# �ü� ;   \x3B
	return if ( grep( /\x3C/, @parts ) ) ;		# �ü� <   \x3C
	return if ( grep( /\x3E/, @parts ) ) ;		# �ü� >   \x3E
	return if ( grep( /\x5B/, @parts ) ) ;		# �ü� [   \x5B
	return if ( grep( /\x5C/, @parts ) ) ;		# �ü� \   \x5C
	return if ( grep( /\x5D/, @parts ) ) ;		# �ü� ]   \x5D
	return if ( grep( /\x7F/, @parts ) ) ;		# ����ʸ�� \x7F

	return if ( grep( /\x2E\x2E/, @parts ) ) ;	# �ɥåȤ�Ϣ³
	return if ( $parts[1] =~ /^\x2E/ ) ;		# domain ��Ƭ�Υɥå�
	return if ( $parts[1] =~ /\x2E$/ ) ;		# domain �����Υɥå�

	( $mail_address ) ;
}

sub decode_form {
	local $buffer;
	local $content_type;
	local $bound;
	local $tmp;
	local $boundary;
	local @formdata;
	local @formpart;
	local $pair;
	local @pairs;
	local $name;
	local $mime_type;
	local $value;

	if ($ENV{'REQUEST_METHOD'} eq "POST") {
	        read(STDIN,$buffer, $ENV{'CONTENT_LENGTH'});
	} elsif ($ENV{'REQUEST_METHOD'} eq "GET" ) {
	        $buffer = $ENV{'QUERY_STRING'};
	}

	($content_type,$bound) = split(/;/,$ENV{'CONTENT_TYPE'});
	($tmp,$boundary) = split(/=/,$bound);

	if ($content_type eq "multipart/form-data") {
		$buffer =~ /^(.+)\r\n/;
		@pairs = split(/--$boundary/,$buffer);

		foreach $pair(@pairs){
			if ($pair) {
				@formdata = split(/\n/,$pair);
				@formpart = split(/;/,$formdata[1]);
				$formpart[1] =~ s/^.+"(.+)".*$/$1/;
				$name = $formpart[1];
				if ($formdata[2]) {
					($tmp,$mime_type) = split (/:/,$formdata[2]);
					$FORM_MIME{$name} = $mime_type;
				}
				$value = "";
				unless ($FORM_MIME{$name}) {
					for ($i = 3;$i <= $#formdata; $i++) {
						$value .= "$formdata[$i]\n";
					}
					$value=~ s/(.+)\r\n$/$1/;
					$value=~ s/(.+)\n$/$1/;
				} else {
					for ($i = 4;$i <= $#formdata; $i++) {
						$value .= "$formdata[$i]\n";
					}
				}
				if ($name && $value) {
					if ($FORM{$name}) {
			        	$FORM{$name}=$FORM{$name}.",".$value;
					} else {
						$FORM{$name}=$value;
					}
				}
			}
		}
	} else {

		@pairs = split(/&/,$buffer);

		foreach $pair(@pairs)
		{
		        ($name,$value) = split(/=/,$pair,2);
		        $value=~tr/+/ /;
		        $value=~tr/\t//;
		        $value=~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
				if ($FORM{$name}) {
		        	$FORM{$name}=$FORM{$name}.",".$value;
				} else {
					$FORM{$name}=$value;
				}
		}
	}
}

&decode_form;

1;

