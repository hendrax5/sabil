-- Migration: Add WireGuard fields to vpn_servers and vpn_clients
-- Date: 2026

-- Add WireGuard fields to vpn_servers
ALTER TABLE vpn_servers ADD COLUMN IF NOT EXISTS wgEnabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE vpn_servers ADD COLUMN IF NOT EXISTS wgPublicKey TEXT;
ALTER TABLE vpn_servers ADD COLUMN IF NOT EXISTS wgPort INTEGER DEFAULT 51820;

-- Add WireGuard peer key fields to vpn_clients
ALTER TABLE vpn_clients ADD COLUMN IF NOT EXISTS clientPublicKey TEXT;
ALTER TABLE vpn_clients ADD COLUMN IF NOT EXISTS clientPrivateKey TEXT;
