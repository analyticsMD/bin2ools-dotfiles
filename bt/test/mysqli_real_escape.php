#!/usr/local/bin/php
<?php

$std_input_data = '';
$mysqli             = new mysqli('127.0.0.1', 'username', 'pass', 'mysql');


if( ftell(STDIN) !== false  )       $std_input_data = stream_get_contents(STDIN);
if( empty($std_input_data)  )       exit('No input piped in');
if( mysqli_connect_errno( ) )       exit('Could not connect to database');

fwrite  (   STDOUT, 
            $mysqli->real_escape_string($std_input_data) 
        );

exit(0);

?>

