#EDGE Libraries includes BSD Socket Library
#use with perl 5.003 or later
#
#Version 1.243 (build 990217)
$version = "1.243";
#
#(c) 1996-1999 Livin' on the EDGE Limited.,
#and taka@edge.co.jp,tsuka@edge.co.jp
#
#◆◆◆◆使用上の注意点◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
#Socket.pmとFcntl.pmが必要です。perlのlibraryのディレクトリをチェックしてください。
#nslookupのパスをチェックしてください。大体/usr/sbinか、/usr/binにあります。
#lock libraryのテストを行ってください
#◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
#
#
$db_suffix = ".db"; #Berckley DB(BSD系OS)の場合
#$db_suffix = ".dir"; #NDBM(Solaris等)の場合

use Socket;
require 5.003;
use File::Copy 'cp';

sub touch
# fileを作る
# 使用法: &touch( file );
# 例: &touch ("/export/home/www/tmp");
# 返り値 : なし
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
# テーブルを読み込む
# 使用法 : &readtbl( ファイル名 );
# 帰り値 : テーブルの配列
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
# DBMファイルのvalueを小さい順にソートしたkeyを返す
# 使用法 : &DBMsort(ファイル名);
#          &DBMsort(ファイル名, 数);
# 使用例 : &DBMsort($file, 10);
# 返り値 : キーのリスト

  local($file) = shift;
  local($num) = shift;

  &DBMsort($file, $num, 'r');
}

sub DBMsort{
# DBMファイルのvalueを大きい順にソートしたkeyを返す
# 使用法 : &DBMsort(ファイル名);
#          &DBMsort(ファイル名, 数);
#          &DBMsort(ファイル名, 数, 'r'); DBMrsort用
# 使用例 : &DBMsort($file, 10);
# 返り値 : キーのリスト

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
# DBMファイル中のキーを返す
# 使用法 : &DBMkeys(ファイル名);
# 使用例 : &DBMexist($file);
# 返り値 : キーのリスト

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
# DBMファイル中にキーが存在するかどうか調べる.
# 使用法 : &DBMexist( ファイル名, キー );
# 使用例 : &DBMexist( $file, $key );
# 返り値 : 真 : 存在する, 偽 : 存在しない
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
# DBMファイル中のキーにデータリストを入れる
# 使用法 : &DBMstore( ファイル名, キー, データリスト );
# 使用例 : &DBMstore( $file, $key, @data );
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
# DBMファイル中のキーのデータリストを読み出す
# 使用法 : &DBMfetch( ファイル名, キー );
# 使用例 : &DBMfetch( $file, $key );
# 返り値 : データリスト
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
# DBMファイル中のキーを削除する.
# 使用法 : &DBMdelete( ファイル名, キー );
# 使用例 : &DBMfetch( $file, $key );
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
# カウント用ファイル中のカウント数を指定の数だけ[加/減]算する
# 数の指定がない時はマジックインクリメント(ex. ABCD0001 -> ABCD0002)
# 数に0を指定すると何もせず現在のファイルの中身(=カウント数)を返す
# 使用法: &count( ファイル[, 数] );
# 使用例: $id = &count( $maxidfile, -1 ); # デクリメント(1だけ減算)
#         $id = &count( $maxidfile );   # マジックインクリメント
#         $presentid = &count( $maxidfile, 0 ); # 現在のカウント数を調べる
# 返り値: [加/減]算後のカウント数, または現在のカウント数(0指定時)
# 備  考: ファイルの中の数字の形式は /^[0-9]*\n?$/ または /^[A-Za-z]*[0-9]*$/
#         また誤って目的のファイル以外の普通のファイルにこの関数を使用して
#         しまった場合, ファイルの中身を消失させてしまう危険が大きいので注意.
{
  my $file = shift;
  my $count = shift;
  my $number;


  if( -e $file )
  {
    cp ($file, $file.".old"); # バックアップ
  }
  else
  {
    touch ($file); # ファイルがなければ作る
  }

  open( COUNT, "+<$file" ) || &htmldie(__LINE__, "Can't open file: $!\n");
  &lock( COUNT );
  $number = <COUNT>;

  unless( defined $count && $count == 0 )
  {
    if( defined $count )
    {
      $number += $count; # 指定された数だけインクリメント/デクリメント
    }
    else
    {
      $number =~ s/\n//; # マジックインクリメントのため末尾\nを削除
      $number++; # 文字列をマジックインクリメント
    }
    truncate( COUNT, 0 ); # ファイルサイズを0にする(デクリメント時の対策)
#    open( ZERO, ">$file" ) && close( ZERO ); # truncate が実装されてない場合
    seek( COUNT, 0, 0 ); # ファイルポインタを先頭に移動
    print COUNT $number;
  }
  &unlock( COUNT );
  close( COUNT );

  $number;
}


sub open_socket_connection
#Socketをオープンする。
#使用法:&open_socket_connection(FILEHANDLE, 接続するhostname, port番号);
#返り値:ステータス（1:成功; 0:失敗）
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


	# ソケットをオープン
	 socket( $file_handle, PF_INET, SOCK_STREAM, $proto ) || return (0);


	# ソケットをリモートネットワークアドレスにコネクト
	connect( $file_handle, $sin ) || return (0);
	my $oldhandle = select($file_handle); $| = 1; select($oldhandle);	# ソケットをバッファリングしない

	1;
}

sub close_socket_connection
#Socketをクローズする。
#使用法:&open_socket_connection(FILEHANDLE);
#返り値:ステータス（1:成功）
{
	my $file_handle = shift;
	close($file_handle);
	1;
}

sub get_html_status
#あるURLのhtmlファイルその他が存在するかどうか確かめる。
#使用法:&get_html_status(URL, timeout値)
#返り値:HTTPステータス＆ヘッダ情報、unable_to_connect
{
		my $url = shift;
		my $timeout = shift;
		$SIG{'ALRM'} = "html_status_timeout";
		alarm ($timeout);

		my $user_agent = "Cyberhorse/0.2";
		chop( my $user_host = `hostname` );
		my $user_protcol = "HTTP/1.0";

		my $port;

		# ポート番号設定
		if ($url =~/^http:\/\//i) {
			$port = 80;
			$url =~s/http:\/\///i;
		} else {
			return "unable_to_connect";
		}

		# ホスト名、ディレクトリ設定
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

  "$year年$mon月$mday日 $hour時$min分$sec秒"; # 98/03/12 tsuka@edge.co.jp
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
#  $year = sprintf "%02d", ($year%100) ;  # 西暦4桁を渡す場合はこの行をコメントアウトする
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
# メールを送る(メッセージID、Dateヘッダ付き)
# 使用法 : &mail_id(
#ローカルsmtpサーバアドレス, fromアドレス,メッセージ,メッセージID,toアドレスのリスト);
# 返り値 :
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

	$port = getservbyname( 'smtp', 'tcp' );	# SMTPポート番号取得

	$SIG{'ALRM'} = "smtp_status_timeout";
	alarm (120);
	&open_socket_connection(SMTP, $local_smtp, $port) || return (0);

	while( <SMTP> )	{
		if(( /^220/ ) && !$hello ) {
						$hello++;
			print SMTP "HELO $local_smtp\r\n";
			# HELOコマンド(full address)
		} elsif ( /^250/ && !$from && $hello ) {
						$from ++;
						print SMTP "MAIL From: <$admin>\r\n";
			# MAIL From:コマンド(<from address>)

		} elsif( /^250/ && !$rcpt && $from && !$rcpt_in_progress) {
			$address = shift (@address_cluster);
						# RCPT To: コマンド(<to address>)
			 		print SMTP "RCPT To: <$address>\r\n";
			$rcpt_in_progress ++;

		} elsif( /^[2345]/ && !$rcpt && $rcpt_in_progress ) {
					if (/^25[01]/) {
					$rcpt_success++;
				}
							if ($address = shift (@address_cluster)) {
						# RCPT To: コマンド(<to address>)
					print SMTP "RCPT To: <$address>\r\n";
						 	} else {
										$rcpt++;
						undef $rcpt_in_progress;
					unless ($rcpt_success) {
						$checked++;
					}
								$data ++;
								print SMTP "DATA\r\n";		# DATAコマンド
				}

		} elsif( /^354/ && !$sent && $data ) {
				 		$sent ++;
				print SMTP $mes;
				print SMTP "\r\n.\r\n";			#メール送信完了

		} elsif( /^250/ && $sent ) {
			$checked++;

			#エラー処理
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
# メールを送る
# 使用法 : &mail( ローカルsmtpサーバアドレス, fromアドレス,メッセージ,toアドレスのリスト);
# 返り値 :
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

	my $port = getservbyname( 'smtp', 'tcp' );	# SMTPポート番号取得

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
			# HELOコマンド(full address)
		} elsif ( /^250/ && !$from && $hello ) {
            $from ++;
            print SMTP "MAIL From: <$admin>\r\n";
			# MAIL From:コマンド(<from address>)

		} elsif( /^250/ && !$rcpt && $from && !$rcpt_in_progress) {
			$address = shift (@address_cluster);
            # RCPT To: コマンド(<to address>)
       		print SMTP "RCPT To: <$address>\r\n";
			$rcpt_in_progress ++;

		} elsif( /^[2345]/ && !$rcpt && $rcpt_in_progress ) {
		    	if (/^25[01]/) {
					$rcpt_success++;
				}
            	if ($address = shift (@address_cluster)) {
            # RCPT To: コマンド(<to address>)
					print SMTP "RCPT To: <$address>\r\n";
             	} else {
                    $rcpt++;
	    			undef $rcpt_in_progress;
					unless ($rcpt_success) {
						$checked++;
					}
            		$data ++;
            		print SMTP "DATA\r\n";		# DATAコマンド
				}

		} elsif( /^354/ && !$sent && $data ) {
	       		$sent ++;
				print SMTP $mes;
				print SMTP "\r\n.\r\n";			#メール送信完了

		} elsif( /^250/ && $sent ) {
			$checked++;

			#エラー処理
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
# e-mail アドレスをチェックする
# 使用法 : &addresscheck( e-mailアドレスのリスト );
# 返り値 : 正常なアドレスのリスト

	my @addresses = @_;
	my @newaddresses;
	chop( my $localhost = `hostname` );
	my $admin = "postmaster\@$localhost";

	foreach $address ( @addresses ) {
	    local( $login, $domain ) = split( /@/, $address );


	    my $remotehost = &gethost( $domain ) if $domain;	# ドメイン名検査

	    if( $remotehost ) {
			my $port = getservbyname( 'smtp', 'tcp' );	# SMTPポート番号取得

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
		            print SMTP "HELO $localhost\r\n";	# HELOコマンド(full address)
				} elsif ( /^250/ && !$from && $hello ) {
		            $from ++;
		            print SMTP "MAIL From: <$admin>\r\n";	# MAIL From:コマンド(<from address>)
				} elsif( /^250/ && !$rcpt && $from ) {
		            $rcpt ++;
		            print SMTP "RCPT To: <$address>\r\n";	# RCPT To: コマンド(<to address>)
				} elsif( (/^25[01]/) && $rcpt ) {

					# 250:成功
					# 251:フォワード先表示(mailerは転送しない)
					# 450:メールボックスがビジー

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
# ドメイン名が正しいかどうかを検査する
# 使用法 : &gethost( ドメイン名 );
# 返り値 : 検査済みドメイン名(またはホスト名)
#          未定義 : ドメインが存在しない
{
  my $domain = shift;
  my $host;

	# type =MX
  $host = &nslookuphost( $domain, MX, 'mail exchanger = ' );
	# type = A
  $host = $host ? $host : &nslookuphost( $domain, A, 'Name:    ' );
}

sub nslookuphost
# nslookupを用いてドメイン名を検査する. タイプ( MX or A )とパターンは対.
# 使用法 : &nslookuphost( ドメイン名, タイプ, パターン );
# 返り値 : 検査済みドメイン名(またはホスト名)
#          未定義 : ドメインが存在しない
{
  my $domain = shift;
  my $type = shift;
  my $pattern = shift;
  my $host;

	if ($domain  =~ /[;><&\*'\|]/) {
	        die "Program Alert: What are you trying to do!? $!\n";
	}

  open ( SAVEERR, ">&STDERR" );	# 標準エラー出力をバックアップ
  close( STDERR );		# 標準エラー出力をクローズ

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

  open( STDERR, ">&SAVEERR" );	# バックアップした標準エラー出力を復帰

  $host;
}

sub echeck {
# emailアドレスが正しいかどうかを検査する
# 使用法 : &echeck( emailアドレス );
# 返り値 : 正しいならメールアドレスを返す
#          未定義 : emailアドレスが正しくない

	my ( $mail_address ) = shift;

	my ( @parts ) = split( /\@/, $mail_address ) ;	# local-port @ domain
	return if ( @parts != 2 ) ;
	return if ( !$parts[0] ) ;
	return if ( !$parts[1] ) ;

	return if ( grep( /[\x80-\xFF]/, @parts ) ) ;	# ASCII以外
	return if ( grep( /[\x00-\x1F]/, @parts ) ) ;	# 制御文字 \x00-\x1F
	return if ( grep( /\x20/, @parts ) ) ;		# スペース \x20
	return if ( grep( /\x22/, @parts ) ) ;		# 特殊 "   \x22
	return if ( grep( /\x28/, @parts ) ) ;		# 特殊 (   \x28
	return if ( grep( /\x29/, @parts ) ) ;		# 特殊 )   \x29
	return if ( grep( /\x2C/, @parts ) ) ;		# 特殊 ,   \x2C
	return if ( grep( /\x3A/, @parts ) ) ;		# 特殊 :   \x3A
	return if ( grep( /\x3B/, @parts ) ) ;		# 特殊 ;   \x3B
	return if ( grep( /\x3C/, @parts ) ) ;		# 特殊 <   \x3C
	return if ( grep( /\x3E/, @parts ) ) ;		# 特殊 >   \x3E
	return if ( grep( /\x5B/, @parts ) ) ;		# 特殊 [   \x5B
	return if ( grep( /\x5C/, @parts ) ) ;		# 特殊 \   \x5C
	return if ( grep( /\x5D/, @parts ) ) ;		# 特殊 ]   \x5D
	return if ( grep( /\x7F/, @parts ) ) ;		# 制御文字 \x7F

	return if ( grep( /\x2E\x2E/, @parts ) ) ;	# ドットの連続
	return if ( $parts[1] =~ /^\x2E/ ) ;		# domain 先頭のドット
	return if ( $parts[1] =~ /\x2E$/ ) ;		# domain 末尾のドット

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

