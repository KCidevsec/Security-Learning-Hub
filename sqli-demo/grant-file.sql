-- grant-file.sql
-- This script grants FILE privilege to dvwa user
-- Runs as root during container initialization

GRANT FILE ON *.* TO 'dvwa'@'%';
GRANT FILE ON *.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;

-- Verify the grant was applied
SELECT User, Host, File_priv FROM mysql.user WHERE User='dvwa';