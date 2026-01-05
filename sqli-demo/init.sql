-- init.sql
-- Database initialization script (same as DVWA)

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` int(6) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(15) NOT NULL,
  `last_name` varchar(15) NOT NULL,
  `user` varchar(15) NOT NULL,
  `password` varchar(32) NOT NULL,
  `avatar` varchar(70) NOT NULL,
  `last_login` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `failed_login` int(3) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Insert sample users (same as DVWA)
INSERT INTO `users` (`user_id`, `first_name`, `last_name`, `user`, `password`, `avatar`, `last_login`, `failed_login`) VALUES
(1, 'admin', 'admin', 'admin', '5f4dcc3b5aa765d61d8327deb882cf99', '/hackable/users/admin.jpg', '2024-01-01 00:00:00', 0),
(2, 'Gordon', 'Brown', 'gordonb', 'e99a18c428cb38d5f260853678922e03', '/hackable/users/gordonb.jpg', '2024-01-01 00:00:00', 0),
(3, 'Hack', 'Me', 'hackme', '0d107d09f5bbe40cade3de5c71e9e9b7', '/hackable/users/hackme.jpg', '2024-01-01 00:00:00', 0),
(4, 'Pablo', 'Picasso', 'pablo', '0d107d09f5bbe40cade3de5c71e9e9b7', '/hackable/users/pablo.jpg', '2024-01-01 00:00:00', 0),
(5, 'Bob', 'Smith', 'smithy', '5f4dcc3b5aa765d61d8327deb882cf99', '/hackable/users/smithy.jpg', '2024-01-01 00:00:00', 0);

-- Create additional table for demonstrating advanced techniques
CREATE TABLE IF NOT EXISTS `secrets` (
  `id` int(6) NOT NULL AUTO_INCREMENT,
  `secret_data` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `secrets` (`id`, `secret_data`) VALUES
(1, 'FLAG{sql_injection_master}'),
(2, 'Secret API Key: abc123xyz789'),
(3, 'Admin Password Reset Token: token_12345');