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

$stmt = $conn->prepare("SELECT username,comment FROM comments");
$stmt->execute();
$stmt->store_result();

$HTML = <<<THEEND
<html>
<head>
<h3>Please sign our guest book below!</h3>
</head>
<body>
<form action="action.php" method="post">
  Username<br>
  <input type="text" name="username" value="">
  <br>
  Comment<br>
  <input type="text" name="comment" value="">
  <br><br>
  <input type="submit" value="Submit">
</form> 

<p>If you click the "Submit" button, you will add your comment to the guest book</p>
<table style="border:1px solid black">
<tr>
<th>User</th>
<th>Comment</th>
</tr>
THEEND;
print $HTML;

$stmt->bind_result($cuser,$ccontent);
while ($stmt->fetch()) {
	print "<tr>";
	print "<td>";
	print $cuser;
	print "</td>";
	print "<td>";
	print $ccontent;
	print "</td>";
	print "</tr>";
}
$HTML = <<<THEEND
</table>
</body>
</html>
THEEND;
print $HTML;

$stmt->close();
$conn->close();


?>
