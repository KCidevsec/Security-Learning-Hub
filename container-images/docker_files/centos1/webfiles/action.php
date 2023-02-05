<?php
$servername = "localhost";
$username = "root";
$password = "test";
$dbname = "data";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

print_r($_POST);
$usernamedata = $_POST['username'];
$commentdata = $_POST['comment'];

$stmt = $conn->prepare("INSERT INTO comments (username, comment) VALUES (?, ?)");
$stmt->bind_param("ss", $usernamedata, $commentdata);

$stmt->execute();
$stmt->close();
$conn->close();

header( 'Location: /index.php' ) ;

?>