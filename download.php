<?php
$name=$_GET["name"];
$file="downloads/" . $name;
if ( file_exists($file) ) {
	header('Content-Description: File Transfer');
	header('Content-type: text/plain');
	header('Content-disposition: attachment; filename="'.basename($file).'"');
	header('Expires: 0');
	header('Cache-Control: must revailidate');
	header('Pragma: public');
	header('Content-Length: ' . filesize($file));
	readfile($file);
	exit;
}
?>
