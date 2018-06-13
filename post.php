<?php $pagetitle="www.julianrutledge.com"?>
<?php include 'includes/top.php';?>
</head>
<body>
<?php include 'includes/head.php';?>
<div id="container">
<?php include 'includes/menu.php'?>
<?php $page_id=$_GET["id"] ?>
<?php 
if ( is_numeric($page_id) && $page_id > 0 && $page_id <= 3 ) {
	include 'includes/posts/' . $page_id . ".php";
} else {
	include 'includes/404.php';
}
?>
<?php include 'includes/foot.php'?>
<?php include 'includes/bottom.php'?>
