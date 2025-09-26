-- Modern Blog Database Schema
-- This schema includes all essential features for a complete blog system

-- Users table for authentication and user management
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    bio TEXT,
    avatar_url VARCHAR(500),
    role ENUM('admin', 'editor', 'author', 'subscriber') DEFAULT 'subscriber',
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires DATETIME,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_created_at (created_at)
);

-- Categories table for organizing posts
CREATE TABLE categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    parent_id BIGINT,
    meta_title VARCHAR(255),
    meta_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_slug (slug),
    INDEX idx_parent_id (parent_id),
    INDEX idx_sort_order (sort_order)
);

-- Tags table for flexible post labeling
CREATE TABLE tags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color VARCHAR(7), -- For hex color codes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_slug (slug),
    INDEX idx_name (name)
);

-- Posts table - main content table
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    excerpt TEXT,
    content LONGTEXT NOT NULL,
    featured_image VARCHAR(500),
    status ENUM('draft', 'published', 'scheduled', 'archived') DEFAULT 'draft',
    post_type ENUM('post', 'page', 'custom') DEFAULT 'post',
    author_id BIGINT NOT NULL,
    category_id BIGINT,
    is_featured BOOLEAN DEFAULT FALSE,
    is_sticky BOOLEAN DEFAULT FALSE,
    allow_comments BOOLEAN DEFAULT TRUE,
    password VARCHAR(255), -- For password protected posts
    scheduled_at DATETIME,
    published_at DATETIME,
    
    -- SEO fields
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords VARCHAR(500),
    canonical_url VARCHAR(500),
    
    -- Analytics
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    share_count BIGINT DEFAULT 0,
    
    -- Reading time in minutes
    reading_time INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    
    INDEX idx_slug (slug),
    INDEX idx_status (status),
    INDEX idx_author_id (author_id),
    INDEX idx_category_id (category_id),
    INDEX idx_is_featured (is_featured),
    INDEX idx_published_at (published_at),
    INDEX idx_view_count (view_count),
    INDEX idx_created_at (created_at),
    FULLTEXT idx_search (title, content, excerpt)
);

-- Post-Tag relationship table (many-to-many)
CREATE TABLE post_tags (
    post_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    
    INDEX idx_post_id (post_id),
    INDEX idx_tag_id (tag_id)
);

-- Comments table with threading support
CREATE TABLE comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    parent_id BIGINT, -- For threaded comments
    author_id BIGINT, -- NULL for guest comments
    author_name VARCHAR(100), -- For guest comments
    author_email VARCHAR(255), -- For guest comments
    author_website VARCHAR(500), -- For guest comments
    author_ip VARCHAR(45),
    content TEXT NOT NULL,
    status ENUM('approved', 'pending', 'spam', 'trash') DEFAULT 'pending',
    is_pinned BOOLEAN DEFAULT FALSE,
    like_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_post_id (post_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_author_id (author_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Media/File uploads table
CREATE TABLE media (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    width INT, -- For images
    height INT, -- For images
    alt_text VARCHAR(255),
    caption TEXT,
    uploaded_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_uploaded_by (uploaded_by),
    INDEX idx_mime_type (mime_type),
    INDEX idx_created_at (created_at)
);

-- Post views tracking for analytics
CREATE TABLE post_views (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT, -- NULL for guest views
    ip_address VARCHAR(45),
    user_agent TEXT,
    referer VARCHAR(500),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_viewed_at (viewed_at),
    INDEX idx_ip_address (ip_address)
);

-- User likes on posts
CREATE TABLE post_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT,
    ip_address VARCHAR(45), -- For guest likes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_user_like (post_id, user_id),
    UNIQUE KEY unique_ip_like (post_id, ip_address),
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- User likes on comments
CREATE TABLE comment_likes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    comment_id BIGINT NOT NULL,
    user_id BIGINT,
    ip_address VARCHAR(45), -- For guest likes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_user_like (comment_id, user_id),
    UNIQUE KEY unique_ip_like (comment_id, ip_address),
    INDEX idx_comment_id (comment_id),
    INDEX idx_user_id (user_id)
);

-- Newsletter subscribers
CREATE TABLE newsletter_subscribers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    status ENUM('subscribed', 'unsubscribed', 'pending') DEFAULT 'pending',
    confirmation_token VARCHAR(255),
    subscribed_at TIMESTAMP,
    unsubscribed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Contact form submissions
CREATE TABLE contact_submissions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    message TEXT NOT NULL,
    ip_address VARCHAR(45),
    status ENUM('new', 'read', 'replied', 'archived') DEFAULT 'new',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_email (email)
);

-- Site settings/options
CREATE TABLE settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value LONGTEXT,
    setting_type ENUM('string', 'number', 'boolean', 'json', 'text') DEFAULT 'string',
    is_autoload BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_setting_key (setting_key),
    INDEX idx_is_autoload (is_autoload)
);

-- User sessions for authentication
CREATE TABLE user_sessions (
    id VARCHAR(255) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_last_activity (last_activity)
);

-- Related posts (manually curated or algorithm-based)
CREATE TABLE related_posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    related_post_id BIGINT NOT NULL,
    relation_type ENUM('manual', 'auto') DEFAULT 'manual',
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (related_post_id) REFERENCES posts(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_relation (post_id, related_post_id),
    INDEX idx_post_id (post_id),
    INDEX idx_related_post_id (related_post_id),
    INDEX idx_sort_order (sort_order)
);

-- Menu system for navigation
CREATE TABLE menus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(50) NOT NULL, -- 'primary', 'footer', 'sidebar', etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_location (location)
);

-- Menu items
CREATE TABLE menu_items (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    menu_id BIGINT NOT NULL,
    parent_id BIGINT,
    title VARCHAR(255) NOT NULL,
    url VARCHAR(500),
    post_id BIGINT, -- If linking to a post
    category_id BIGINT, -- If linking to a category
    sort_order INT DEFAULT 0,
    target VARCHAR(20) DEFAULT '_self',
    css_class VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES menu_items(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    
    INDEX idx_menu_id (menu_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_sort_order (sort_order)
);

-- Insert some default data
INSERT INTO settings (setting_key, setting_value, setting_type, is_autoload, description) VALUES
('site_title', 'My Blog', 'string', TRUE, 'Site title'),
('site_tagline', 'Just another blog', 'string', TRUE, 'Site tagline'),
('site_url', 'https://myblog.com', 'string', TRUE, 'Site URL'),
('posts_per_page', '10', 'number', TRUE, 'Number of posts per page'),
('comments_enabled', 'true', 'boolean', TRUE, 'Enable comments globally'),
('comment_moderation', 'true', 'boolean', TRUE, 'Moderate comments before publishing'),
('registration_enabled', 'true', 'boolean', TRUE, 'Allow user registration'),
('default_user_role', 'subscriber', 'string', TRUE, 'Default role for new users');

-- Insert default categories
INSERT INTO categories (name, slug, description) VALUES
('Uncategorized', 'uncategorized', 'Default category for posts'),
('Technology', 'technology', 'Posts about technology and innovation'),
('Lifestyle', 'lifestyle', 'Posts about lifestyle and personal experiences'),
('Travel', 'travel', 'Posts about travel and adventures');

-- Insert default menu
INSERT INTO menus (name, location) VALUES
('Primary Menu', 'primary'),
('Footer Menu', 'footer');

-- Create some useful views
CREATE VIEW published_posts AS
SELECT 
    p.*,
    u.username as author_name,
    u.first_name,
    u.last_name,
    c.name as category_name,
    c.slug as category_slug
FROM posts p
LEFT JOIN users u ON p.author_id = u.id
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'published' 
AND (p.scheduled_at IS NULL OR p.scheduled_at <= NOW());

CREATE VIEW post_stats AS
SELECT 
    p.id,
    p.title,
    p.view_count,
    p.like_count,
    COUNT(DISTINCT c.id) as comment_count,
    COUNT(DISTINCT cl.id) as total_likes
FROM posts p
LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'approved'
LEFT JOIN post_likes cl ON p.id = cl.post_id
GROUP BY p.id, p.title, p.view_count, p.like_count;