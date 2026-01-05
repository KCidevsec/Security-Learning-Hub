<?php
// check.php - Diagnostic page
// Place this in src/ directory
?>
<!DOCTYPE html>
<html>
<head>
    <title>Diagnostic Check</title>
    <style>
        body { font-family: monospace; padding: 20px; background: #f5f5f5; }
        .box { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f0f0f0; padding: 10px; overflow: auto; }
    </style>
</head>
<body>
    <h1>System Diagnostic</h1>
    
    <div class="box">
        <h2>Current User</h2>
        <pre><?php echo shell_exec('whoami'); ?></pre>
        <pre><?php echo shell_exec('id'); ?></pre>
    </div>
    
    <div class="box">
        <h2>Web Root Directory Listing</h2>
        <pre><?php echo shell_exec('ls -lah /var/www/html/'); ?></pre>
    </div>
    
    <div class="box">
        <h2>Web Root Permissions</h2>
        <pre><?php echo shell_exec('ls -ld /var/www/html/'); ?></pre>
    </div>
    
    <div class="box">
        <h2>PHP Files in Web Root</h2>
        <pre><?php echo shell_exec('find /var/www/html/ -name "*.php"'); ?></pre>
    </div>
    
    <div class="box">
        <h2>Test File Creation</h2>
        <?php
        $testFile = '/var/www/html/write_test.txt';
        if (file_put_contents($testFile, 'test')) {
            echo "<p class='success'>✓ Can write to /var/www/html/</p>";
            unlink($testFile);
        } else {
            echo "<p class='error'>✗ Cannot write to /var/www/html/</p>";
        }
        ?>
    </div>
    
    <div class="box">
        <h2>Database Connection</h2>
        <?php
        $db_host = getenv('DB_HOST') ?: 'db';
        $db_user = getenv('DB_USER') ?: 'dvwa';
        $db_pass = getenv('DB_PASS') ?: 'p@ssw0rd';
        $db_name = getenv('DB_NAME') ?: 'dvwa';
        
        $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
        
        if ($conn->connect_error) {
            echo "<p class='error'>✗ Database connection failed</p>";
        } else {
            echo "<p class='success'>✓ Database connected</p>";
            
            // Check FILE privilege
            $result = $conn->query("SHOW GRANTS FOR CURRENT_USER()");
            echo "<h3>Current User Grants:</h3><pre>";
            while ($row = $result->fetch_row()) {
                echo $row[0] . "\n";
            }
            echo "</pre>";
            
            // Check secure_file_priv
            $result = $conn->query("SHOW VARIABLES LIKE 'secure_file_priv'");
            echo "<h3>MySQL secure_file_priv:</h3><pre>";
            while ($row = $result->fetch_assoc()) {
                echo $row['Variable_name'] . " = " . $row['Value'] . "\n";
            }
            echo "</pre>";
            
            $conn->close();
        }
        ?>
    </div>
</body>
</html>